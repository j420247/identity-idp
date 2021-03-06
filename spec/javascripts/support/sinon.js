import sinon from 'sinon';

/**
 * Returns an instance of a Sinon sandbox, and automatically restores all stubbed methods after each
 * test case.
 *
 * @param {sinon.SinonSandboxConfig=} config
 */
export function useSandbox(config) {
  const { useFakeTimers = false, ...remainingConfig } = config ?? {};
  const sandbox = sinon.createSandbox(remainingConfig);

  beforeEach(() => {
    // useFakeTimers overrides global timer functions as soon as sandbox is created, thus leaking
    // across tests. Instead, wait until tests start to initialize.
    if (useFakeTimers) {
      sandbox.useFakeTimers();
    }
  });

  afterEach(() => {
    sandbox.restore();

    if (useFakeTimers) {
      sandbox.clock.restore();
    }
  });

  return sandbox;
}
