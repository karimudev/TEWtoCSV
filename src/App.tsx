import { useState, type ChangeEvent } from "react"
import reactLogo from "./assets/react.svg"
import viteLogo from "/vite.svg"
import "./App.css"

function App() {
    const INSTRUCTIONS_URL = "https://github.com/karimudev/TEWtoCSV/blob/main/INSTRUCTIONS.md";

    const handleUpload = async (event: ChangeEvent<HTMLInputElement>) => {
        if (!event.target.files) {
            return;
        }

        const saveFile = event.target.files[0];
    };

    return (
        <>
            <div>
                <a href="https://vite.dev" target="_blank">
                    <img src={viteLogo} className="logo" alt="Vite logo" />
                </a>
                <a href="https://react.dev" target="_blank">
                    <img src={reactLogo} className="logo react" alt="React logo" />
                </a>
            </div>
            <h1>TEW to CSV</h1>
            <div className="card">
                <label htmlFor="file-upload" className="custom-file-upload">
                    Upload Save File
                </label>
                <input id="file-upload" type="file" onChange={handleUpload}/>
            </div>
            <p className="read-the-docs">
                Click <a href={INSTRUCTIONS_URL} target="_blank">here</a> to view help on how to use
            </p>
        </>
    )
}

export default App
