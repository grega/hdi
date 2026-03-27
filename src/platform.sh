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

  [[ -f "$dir/wrangler.toml" || -f "$dir/wrangler.json" ]] && _platform_add "cloudflare" "Cloudflare" "high" || true
  [[ -f "$dir/vercel.json" ]]       && _platform_add "vercel" "Vercel" "high" || true
  [[ -f "$dir/netlify.toml" ]]      && _platform_add "netlify" "Netlify" "high" || true
  [[ -f "$dir/fly.toml" ]]          && _platform_add "fly" "Fly.io" "high" || true
  [[ -f "$dir/Procfile" ]]          && _platform_add "heroku" "Heroku" "high" || true
  [[ -f "$dir/render.yaml" ]]       && _platform_add "render" "Render" "high" || true
  [[ -f "$dir/firebase.json" ]]     && _platform_add "firebase" "Firebase" "high" || true
  [[ -f "$dir/amplify.yml" ]]       && _platform_add "amplify" "AWS Amplify" "high" || true
  [[ -f "$dir/serverless.yml" || -f "$dir/serverless.ts" ]] && _platform_add "serverless" "Serverless" "high" || true
  [[ -f "$dir/cdk.json" ]]          && _platform_add "awscdk" "AWS CDK" "high" || true
  [[ -f "$dir/pulumi.yaml" ]]       && _platform_add "pulumi" "Pulumi" "high" || true
  [[ -f "$dir/railway.json" || -f "$dir/railway.toml" ]] && _platform_add "railway" "Railway" "high" || true
  [[ -f "$dir/Chart.yaml" ]]        && _platform_add "helm" "Helm" "high" || true
  [[ -f "$dir/CNAME" ]]             && _platform_add "ghpages" "GitHub Pages" "high" || true
  [[ -d "$dir/k8s" || -d "$dir/kubernetes" ]] && _platform_add "kubernetes" "Kubernetes" "high" || true
  [[ -d "$dir/.kamal" || -f "$dir/config/deploy.yml" ]] && _platform_add "kamal" "Kamal" "high" || true

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
    esac
  done
}

# Layer 3: Prose mention detection in deploy section bodies (low confidence)
# Matches are case-insensitive. Captures the most specific variant mentioned
detect_platforms_from_prose() {
  local body
  for body in "${SECTION_BODIES[@]+"${SECTION_BODIES[@]}"}"; do
    [[ -z "$body" ]] && continue

    shopt -s nocasematch
    [[ "$body" =~ Cloudflare[[:space:]]Pages ]]   && _platform_add "cloudflare"  "Cloudflare Pages"   "low" || true
    [[ "$body" =~ Cloudflare[[:space:]]Workers ]]  && _platform_add "cloudflare"  "Cloudflare Workers" "low" || true
    [[ "$body" =~ Vercel ]]                        && _platform_add "vercel"      "Vercel"             "low" || true
    [[ "$body" =~ Netlify ]]                       && _platform_add "netlify"     "Netlify"            "low" || true
    [[ "$body" =~ Heroku ]]                        && _platform_add "heroku"      "Heroku"             "low" || true
    [[ "$body" =~ Fly\.io ]]                       && _platform_add "fly"         "Fly.io"             "low" || true
    [[ "$body" =~ GitHub[[:space:]]Pages ]]        && _platform_add "ghpages"     "GitHub Pages"       "low" || true
    [[ "$body" =~ Dokku ]]                         && _platform_add "dokku"       "Dokku"              "low" || true
    [[ "$body" =~ Railway ]]                       && _platform_add "railway"     "Railway"            "low" || true
    [[ "$body" =~ Render ]]                        && _platform_add "render"      "Render"             "low" || true
    [[ "$body" =~ Firebase ]]                      && _platform_add "firebase"    "Firebase"           "low" || true
    [[ "$body" =~ AWS[[:space:]]Amplify ]]         && _platform_add "amplify"     "AWS Amplify"        "low" || true
    [[ "$body" =~ DigitalOcean ]]                  && _platform_add "digitalocean" "DigitalOcean"      "low" || true
    [[ "$body" =~ Kamal ]]                         && _platform_add "kamal"       "Kamal"              "low" || true
    [[ "$body" =~ Surge ]]                         && _platform_add "surge"       "Surge"              "low" || true
    shopt -u nocasematch
  done
}

# Build a display string from detected platforms
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
