import "./App.css";
import MDBReader, { ColumnTypes } from "mdb-reader";
import initSqlJs, { type Database } from "sql.js";
import query from "./assets/query.sql?raw";
import reactLogo from "./assets/react.svg";
import viteLogo from "/vite.svg";
import wasm from "sql.js/dist/sql-wasm.wasm?url";
import { Buffer } from "buffer";
import { useState, type ChangeEvent } from "react";

const INSTRUCTIONS_URL = "https://github.com/karimudev/TEWtoCSV/blob/main/INSTRUCTIONS.md";

function App() {

    const [status, setStatus] = useState("");

    const handleUpload = async (event: ChangeEvent<HTMLInputElement>) => {
        if (!event.target.files) {
            return;
        }

        const saveFile = event.target.files[0];
        if (saveFile.name != "TEW9Save.mdb") {
            setStatus("Uploaded file is not named \"TEW9Save.mdb\". Are you sure you uploaded the correct file?");
            return;
        }

        let fileReader = new FileReader();
        fileReader.onload = async () => await handleSavefileData(fileReader.result as ArrayBuffer);
        fileReader.onerror = () => setStatus("ERROR: Could not read file");

        fileReader.readAsArrayBuffer(saveFile);
    };

    const handleSavefileData = async (buffer: ArrayBuffer) => {
        const SQL = await initSqlJs({ locateFile: () => wasm });
        const db = new SQL.Database();

        convertMDBtoSQL(buffer, db);
        const queryOutput = runQuery(db);

        setStatus("Done.");
    };

    const convertMDBtoSQL =  (buffer: ArrayBuffer, db: Database) => {
        setStatus("Converting MDB to SQL database...")
        const mdbReader = new MDBReader(Buffer.from(buffer));

        const tablesUsedInQuery = new Set([
            "tblAway",
            "tblBelt",
            "tblContract",
            "tblFed",
            "tblFedBrand",
            "tblGameInfo",
            "tblInjury",
            "tblPact",
            "tblStable",
            "tblTeam",
            "tblWorker",
            "tblWorkerBusiness",
            "tblWorkerOver",
            "tblWorkerSkill",
        ]);

        mdbReader.getTableNames()
            .filter(tableName => tablesUsedInQuery.has(tableName))
            .forEach(tableName => {
                const typeMap = {
                    [ColumnTypes.Boolean]: "INTEGER",
                    [ColumnTypes.Byte]: "INTEGER",
                    [ColumnTypes.Integer]: "INTEGER",
                    [ColumnTypes.Long]: "INTEGER",
                    [ColumnTypes.Currency]: "NUMERIC",
                    [ColumnTypes.Float]: "REAL",
                    [ColumnTypes.Double]: "REAL",
                    [ColumnTypes.DateTime]: "TEXT",
                    [ColumnTypes.Binary]: "BLOB",
                    [ColumnTypes.Text]: "TEXT",
                    [ColumnTypes.OLE]: "BLOB",
                    [ColumnTypes.Memo]: "TEXT",
                    [ColumnTypes.RepID]: "TEXT",
                    [ColumnTypes.Numeric]: "NUMERIC",
                    [ColumnTypes.Complex]: "TEXT",
                    [ColumnTypes.BigInt]: "INTEGER",
                    [ColumnTypes.DateTimeExtended]: "TEXT",
                };

                const table = mdbReader.getTable(tableName);
                const tableColumns = table.getColumns();
                const tableData = table.getData();

                const tableColumnsDefinition = tableColumns
                .map(column => `"${column.name}" ${typeMap[column.type]}`)
                .join(", ");

                db.run(`CREATE TABLE "${tableName}" (${tableColumnsDefinition})`);

                tableData.forEach(row => {
                    const values = tableColumns.map(column => { 
                        const value = row[column.name];

                        if (value === null) {
                            return "null";
                        }

                        if (value instanceof Date) {
                            return `"${value.toISOString().slice(0, 10)} 00:00:00"`;
                        }

                        if (typeof value === "string") {
                            return `"${value.replaceAll("\"", "\"\"")}"`;
                        }

                        return value;
                    }).join(", ");

                    db.run(`INSERT INTO "${tableName}" VALUES (${values})`);
                });
            });
    }

    const runQuery = (db: Database) => {
        setStatus("Extracting data...")
        console.log(db.exec(query));
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
                <p>{status}</p>
            </div>
            <p className="read-the-docs">
                Click <a href={INSTRUCTIONS_URL} target="_blank">here</a> to view help on how to use
            </p>
        </>
    )
}

export default App
