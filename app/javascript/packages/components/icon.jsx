/**
 * @typedef IconProps
 *
 * @prop {string=} className Optional class name to apply to SVG element.
 */

/**
 * Creates a new icon component, accepting common props, and applying common wrapping elements.
 *
 * @param {string} path SVG icon path definition.
 *
 * @return {import('react').FunctionComponent<IconProps>}
 */
function createIconComponent(path) {
  return ({ className }) => (
    <svg
      aria-hidden
      focusable={false}
      role="img"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 512 512"
      className={className}
    >
      <path fill="currentColor" d={path} />
    </svg>
  );
}

const Icon = {
  Camera: createIconComponent(
    'M512 144v288c0 26.5-21.5 48-48 48H48c-26.5 0-48-21.5-48-48V144c0-26.5 21.5-48 48-48h88l12.3-32.9c7-18.7 24.9-31.1 44.9-31.1h125.5c20 0 37.9 12.4 44.9 31.1L376 96h88c26.5 0 48 21.5 48 48zM376 288c0-66.2-53.8-120-120-120s-120 53.8-120 120 53.8 120 120 120 120-53.8 120-120zm-32 0c0 48.5-39.5 88-88 88s-88-39.5-88-88 39.5-88 88-88 88 39.5 88 88z',
  ),
};

export default Icon;
