# next-app

A Next.js application with App Router for a SaaS analytics dashboard. Uses Tailwind CSS, Drizzle ORM, and NextAuth for authentication.

## Getting Started

First, install dependencies:

```bash
npm install
```

Copy the environment file and configure your database connection:

```bash
cp .env.example .env.local
```

Run database migrations:

```bash
npm run db:push
```

Then, run the development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser.

## Testing

Run the test suite:

```bash
npm test
```

Run end-to-end tests with Playwright:

```bash
npx playwright test
```

## Deploy

Build the production bundle:

```bash
npm run build
```

Deploy to Vercel:

```bash
npx vercel --prod
```

## Learn More

See the [Next.js docs](https://nextjs.org/docs).
