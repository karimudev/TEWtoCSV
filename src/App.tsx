import "./App.css";
import MDBReader, { ColumnTypes } from "mdb-reader";
import initSqlJs, { type Database, type QueryExecResult } from "sql.js";
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
        const db = await convertMDBtoSQL(buffer);
        const queryResult = runQuery(db);
        const csvString = formatResultToCsv(queryResult);
        downloadCsv(csvString);

        setStatus("Done.");
    };

    const convertMDBtoSQL =  async (buffer: ArrayBuffer) => {
        setStatus("Converting MDB to SQL database...")
        const mdbReader = new MDBReader(Buffer.from(buffer));
        const SQL = await initSqlJs({ locateFile: () => wasm });
        const db = new SQL.Database();

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

        return db;
    }

    const runQuery = (db: Database) => {
        setStatus("Extracting data...")

        return db.exec(query)[0];
    };

    const formatResultToCsv = (queryResult: QueryExecResult) => {
        setStatus("Formatting data...")

        const avg = (...nums: number[]): number => {
            return nums.reduce((acc, v) => acc + v, 0) / nums.length
        }

        return queryResult.values.map(row => {
            const csvRow = []

            // Personal info
            const name = row.shift() as string;
            const gender = row.shift() as string;
            const age = row.shift() as number;
            const gameHeight = row.shift() as number;
            const weightInKgs = row.shift() as number;

            const feet = Math.floor((gameHeight + 35) / 12);
            const inches = (gameHeight + 35) % 12
            const heightInCms = Math.round(feet * 30.48 + inches * 2.45);

            csvRow.push(name, gender, age, heightInCms, weightInKgs);

            // Popularity and skills
            const popularity = row.shift() as number;
            csvRow.push(popularity)

            const brawling = row.shift() as number;
            const puroresu = row.shift() as number;
            const hardcore = row.shift() as number;
            const technical = row.shift() as number;
            const aerial = row.shift() as number;
            const flashiness = row.shift() as number;
            const primaryMax = Math.max(brawling, puroresu, technical, aerial);
            csvRow.push(primaryMax, brawling, puroresu, hardcore, technical, aerial, flashiness);

            const psychology = row.shift() as number;
            const experience = row.shift() as number;
            const respect = row.shift() as number;
            const reputation = row.shift() as number;
            const mentalAvg = 4 * avg(psychology * 0.97, experience * 0.01, respect * 0.01, reputation * 0.01);
            csvRow.push(mentalAvg, psychology, experience, respect, reputation);

            const charisma = row.shift() as number;
            const microphone = row.shift() as number;
            const acting = row.shift() as number;
            const starQuality = row.shift() as number;
            const sexAppeal = row.shift() as number;
            const menace = row.shift() as number;
            const entertainmentMax = Math.max(charisma, microphone, acting, menace);
            csvRow.push(entertainmentMax, charisma, microphone, acting, starQuality, sexAppeal, menace);

            const basics = row.shift() as number;
            const selling = row.shift() as number;
            const consistency = row.shift() as number;
            const safety = row.shift() as number;
            const stamina = row.shift() as number;
            const athleticism = row.shift() as number;
            const power = row.shift() as number;
            const toughness = row.shift() as number;
            const resilience = row.shift() as number;
            const fundamentalsAvg = avg(basics, selling, consistency, safety, stamina);
            csvRow.push(fundamentalsAvg, basics, selling, consistency, safety, stamina, athleticism, power, toughness, resilience);

            const playByPlay = row.shift() as number;
            const colourSkill = row.shift() as number;
            const refereeing = row.shift() as number;
            const businessRep = row.shift() as number;
            const bookingRep = row.shift() as number;
            const bookingSkill = row.shift() as number;
            const othersMax = Math.max(playByPlay, colourSkill, refereeing, businessRep, bookingRep, bookingSkill);
            csvRow.push(othersMax, playByPlay, colourSkill, refereeing, businessRep, bookingRep, bookingSkill);

            // Perception
            const perception = row.shift() as string;
            const perceptionIdx = row.shift()  as number;
            const momentum = row.shift() as string;
            const momentumIdx = row.shift()  as number;
            csvRow.push(perception, perceptionIdx, momentum, momentumIdx);

            // Contract
            const company = row.shift() as string;
            const brand = row.shift() as string;
            const expiryDate = row.shift() as string;
            const exclusiveContract = row.shift() as number;
            const writtenContract = row.shift() as number;
            const touringContract = row.shift() as number;
            const onLoan = row.shift() as number;
            const developmental = row.shift() as number;
            const amount = row.shift() as number;
            const per = row.shift() as string;
            csvRow.push(company, brand, expiryDate, exclusiveContract, writtenContract, touringContract, onLoan, developmental, amount, per);

            // Role
            const inRing = row.shift() as number;
            const wrestler = row.shift() as number;
            const occasional = row.shift() as number;
            const referee = row.shift() as number;
            const announcer = row.shift() as number;
            const colour = row.shift() as number;
            const manager = row.shift() as number;
            const personality = row.shift() as number;
            const roadAgent = row.shift() as number;
            csvRow.push(inRing, wrestler, occasional, referee, announcer, colour, manager, personality, roadAgent);

            // Character info
            const side = row.shift() as string;
            const teams = row.shift() as string;
            const stables = row.shift() as string;
            const managers = row.shift() as string;
            const belts = row.shift() as string;
            const gimmick = row.shift() as string;
            const gimmickRating = row.shift() as string;
            const ratingIdx = row.shift() as number;
            csvRow.push(side, teams, stables, managers, belts, gimmick, gimmickRating, ratingIdx);

            // Availability
            const absenceReason = row.shift() as string;
            const returnDate = row.shift() as string;
            csvRow.push(absenceReason, returnDate);

            // Misc
            const loyalty = row.shift() as string;
            const debutDate = row.shift() as string;
            csvRow.push(loyalty, debutDate);

            const mappedCsvRow = csvRow.map(value => `"${value === null ? "" : value}"`);
            return mappedCsvRow;
        }).join('\n');
    };

    const downloadCsv = (csvString: string) => {
        const blob = new Blob([csvString], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);

        const link = document.createElement("a");
        link.href = url;

        const filename = "TEWData.csv";
        link.setAttribute("download", filename);

        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        URL.revokeObjectURL(url);
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
