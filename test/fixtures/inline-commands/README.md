# inline-commands

## Available Scripts

In the project directory, you can run:

### `yarn start`

Runs the app in the development mode.\
Open [http://localhost:3011](http://localhost:3011) to view the web component test page in the browser.

### `yarn test`

Launches the test runner in interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `yarn build`

Builds the app for production to the `build` folder.\
It bundles React in production mode and optimizes the build for the best performance.

## Testing

Automated unit tests can be run via the `yarn test` command. These unit tests are written using the JavaScript testing framework `Jest` and make use of the tools provided by the [React Testing Library](https://testing-library.com/docs/). Automated accessibility testing for components is available via the `jest-axe` library. This can be achieved using the `haveNoViolations` matcher provided by `jest-axe`, although this does not guarantee that the tested components have no accessibility issues.

Integration testing is carried out via `cypress` and can be run using:

- `yarn exec cypress run` to run in the CLI
- `yarn exec cypress open` to run in the GUI

Currently, there are `cypress` tests for various aspects of the web component, such as running `python` and `HTML` code and Mission Zero-related functionality.

## Installation

To get started, clone the repo and run `npm install` to install dependencies. Then set up the environment with `npm run setup`.

## Development

Start the dev server:

```bash
npm run dev
```

Or use `npm run dev -- --port 3000` for a custom port.
