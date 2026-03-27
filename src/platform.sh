# ── Platform detection ────────────────────────────────────────────────────────
# Detects deployment platforms from three sources:
#   1. Config files in the project directory (high confidence)
#   2. CLI tools in extracted commands (high confidence)
#   3. Platform names mentioned in deploy section prose (low confidence)

declare -a PLATFORM_GROUPS=()
declare -a PLATFORM_NAMES=()
declare -a PLATFORM_CONFIDENCE=()  # "high" | "low"

# Add or upgrade a platform detection. Deduplicates by group key
# If the group already exists: upgrade confidence to high if applicable,
# and prefer the longer (more specific) name
_platform_add() {
  local group="$1" name="$2" confidence="$3"
  for i in "${!PLATFORM_GROUPS[@]}"; do
    if [[ "${PLATFORM_GROUPS[$i]}" == "$group" ]]; then
      if [[ "$confidence" == "high" ]]; then
        PLATFORM_CONFIDENCE[i]="high"
      fi
      if (( ${#name} > ${#PLATFORM_NAMES[i]} )); then
        PLATFORM_NAMES[i]="$name"
      fi
      return
    fi
  done
  PLATFORM_GROUPS+=("$group")
  PLATFORM_NAMES+=("$name")
  PLATFORM_CONFIDENCE+=("$confidence")
}

# Layer 1: Config file detection (high confidence)
detect_platforms_from_files() {
  local dir="$1"

  if [[ -f "$dir/wrangler.toml" || -f "$dir/wrangler.json" ]]; then _platform_add "cloudflare" "Cloudflare" "high"; fi
  if [[ -f "$dir/vercel.json" ]]; then       _platform_add "vercel" "Vercel" "high"; fi
  if [[ -f "$dir/netlify.toml" ]]; then      _platform_add "netlify" "Netlify" "high"; fi
  if [[ -f "$dir/fly.toml" ]]; then          _platform_add "fly" "Fly.io" "high"; fi
  if [[ -f "$dir/Procfile" ]]; then          _platform_add "heroku" "Heroku" "high"; fi
  if [[ -f "$dir/render.yaml" ]]; then       _platform_add "render" "Render" "high"; fi
  if [[ -f "$dir/firebase.json" ]]; then     _platform_add "firebase" "Firebase" "high"; fi
  if [[ -f "$dir/amplify.yml" ]]; then       _platform_add "amplify" "AWS Amplify" "high"; fi
  if [[ -f "$dir/serverless.yml" || -f "$dir/serverless.ts" ]]; then _platform_add "serverless" "Serverless" "high"; fi
  if [[ -f "$dir/cdk.json" ]]; then          _platform_add "awscdk" "AWS CDK" "high"; fi
  if [[ -f "$dir/pulumi.yaml" ]]; then       _platform_add "pulumi" "Pulumi" "high"; fi
  if [[ -f "$dir/railway.json" || -f "$dir/railway.toml" ]]; then _platform_add "railway" "Railway" "high"; fi
  if [[ -f "$dir/Chart.yaml" ]]; then        _platform_add "helm" "Helm" "high"; fi
  if [[ -f "$dir/CNAME" ]]; then             _platform_add "ghpages" "GitHub Pages" "high"; fi
  if [[ -d "$dir/k8s" || -d "$dir/kubernetes" ]]; then _platform_add "kubernetes" "Kubernetes" "high"; fi
  if [[ -d "$dir/.kamal" || -f "$dir/config/deploy.yml" ]]; then _platform_add "kamal" "Kamal" "high"; fi

  # Terraform: glob for *.tf files
  local _tf
  for _tf in "$dir"/*.tf; do
    if [[ -f "$_tf" ]]; then
      _platform_add "terraform" "Terraform" "high"
      break
    fi
  done

  return 0
}

# Layer 2: CLI tool detection from extracted commands (high confidence)
detect_platforms_from_commands() {
  local tool
  for idx in "${!DISPLAY_LINES[@]}"; do
    [[ "${LINE_TYPES[$idx]}" != "command" ]] && continue
    _check_tool_name "${LINE_CMDS[$idx]}"
    [[ -z "$_CT_RESULT" ]] && continue
    tool="$_CT_RESULT"

    case "$tool" in
      wrangler)              _platform_add "cloudflare"  "Cloudflare"  "high" ;;
      vercel)                _platform_add "vercel"      "Vercel"      "high" ;;
      netlify)               _platform_add "netlify"     "Netlify"     "high" ;;
      flyctl|fly)            _platform_add "fly"         "Fly.io"      "high" ;;
      heroku)                _platform_add "heroku"      "Heroku"      "high" ;;
      firebase)              _platform_add "firebase"    "Firebase"    "high" ;;
      kubectl)               _platform_add "kubernetes"  "Kubernetes"  "high" ;;
      helm)                  _platform_add "helm"        "Helm"        "high" ;;
      kamal)                 _platform_add "kamal"       "Kamal"       "high" ;;
      terraform)             _platform_add "terraform"   "Terraform"   "high" ;;
      pulumi)                _platform_add "pulumi"      "Pulumi"      "high" ;;
      railway)               _platform_add "railway"     "Railway"     "high" ;;
      serverless|sls)        _platform_add "serverless"  "Serverless"  "high" ;;
      sam)                   _platform_add "awssam"      "AWS SAM"     "high" ;;
      cdk)                   _platform_add "awscdk"      "AWS CDK"     "high" ;;
      dokku)                 _platform_add "dokku"       "Dokku"       "high" ;;
      surge)                 _platform_add "surge"       "Surge"       "high" ;;
      docker|docker-compose|podman) _platform_add "docker" "Docker" "high" ;;
    esac
  done
}

# Layer 3: Prose mention detection in deploy section bodies (low confidence)
# Matches are case-insensitive. Captures the most specific variant mentioned.
detect_platforms_from_prose() {
  local body
  for body in "${SECTION_BODIES[@]+"${SECTION_BODIES[@]}"}"; do
    [[ -z "$body" ]] && continue

    shopt -s nocasematch
    if [[ "$body" =~ Cloudflare[[:space:]]Pages ]]; then   _platform_add "cloudflare"   "Cloudflare Pages"   "low"; fi
    if [[ "$body" =~ Cloudflare[[:space:]]Workers ]]; then _platform_add "cloudflare"   "Cloudflare Workers" "low"; fi
    if [[ "$body" =~ Vercel ]]; then                       _platform_add "vercel"       "Vercel"             "low"; fi
    if [[ "$body" =~ Netlify ]]; then                      _platform_add "netlify"      "Netlify"            "low"; fi
    if [[ "$body" =~ Heroku ]]; then                       _platform_add "heroku"       "Heroku"             "low"; fi
    if [[ "$body" =~ Fly\.io ]]; then                      _platform_add "fly"          "Fly.io"             "low"; fi
    if [[ "$body" =~ GitHub[[:space:]]Pages ]]; then       _platform_add "ghpages"      "GitHub Pages"       "low"; fi
    if [[ "$body" =~ Dokku ]]; then                        _platform_add "dokku"        "Dokku"              "low"; fi
    if [[ "$body" =~ Railway ]]; then                      _platform_add "railway"      "Railway"            "low"; fi
    if [[ "$body" =~ Render ]]; then                       _platform_add "render"       "Render"             "low"; fi
    if [[ "$body" =~ Firebase ]]; then                     _platform_add "firebase"     "Firebase"           "low"; fi
    if [[ "$body" =~ AWS[[:space:]]Amplify ]]; then        _platform_add "amplify"      "AWS Amplify"        "low"; fi
    if [[ "$body" =~ DigitalOcean ]]; then                 _platform_add "digitalocean" "DigitalOcean"       "low"; fi
    if [[ "$body" =~ Kamal ]]; then                        _platform_add "kamal"        "Kamal"              "low"; fi
    if [[ "$body" =~ Surge ]]; then                        _platform_add "surge"        "Surge"              "low"; fi
    if [[ "$body" =~ Docker ]]; then                       _platform_add "docker"       "Docker"             "low"; fi
    shopt -u nocasematch
  done
}

# Build a display string from detected platforms.
# High-confidence names are plain; low-confidence get a "?" suffix
# Sets _PLATFORM_DISPLAY (empty string if no platforms detected)
_PLATFORM_DISPLAY=""
build_platform_display() {
  _PLATFORM_DISPLAY=""
  if (( ${#PLATFORM_NAMES[@]} == 0 )); then return; fi
  local parts=""
  for i in "${!PLATFORM_NAMES[@]}"; do
    if [[ -n "$parts" ]]; then parts+=", "; fi
    parts+="${PLATFORM_NAMES[$i]}"
    if [[ "${PLATFORM_CONFIDENCE[$i]}" == "low" ]]; then parts+="?"; fi
  done
  _PLATFORM_DISPLAY="$parts"
}
