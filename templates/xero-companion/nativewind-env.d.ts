/// <reference types="nativewind/types" />

// Teaches TypeScript that React Native core components accept a `className`
// prop (NativeWind v4) and that side-effect CSS imports (e.g.
// `import "../global.css"`) resolve to a module. Without this file, `tsc`
// reports TS2769 on every `className` and TS2882 on the global.css import,
// even though the app builds and runs correctly via the NativeWind metro +
// babel transform. Self-contained per template by design.
declare module "*.css";
