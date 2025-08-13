import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import { nodePolyfills } from "vite-plugin-node-polyfills";
import wasm from "vite-plugin-wasm";
import topLevelAwait from "vite-plugin-top-level-await";

export default defineConfig({
    plugins: [
        react(),
        nodePolyfills(),
        wasm(),
        topLevelAwait()
    ],
    base: "/TEWtoCSV",
})
