import React, { useState } from 'react'

import './App.css'

function App() {
  const [ruleFile1, setRuleFile1] = useState<File | null>(null)
  const [ruleFile2, setRuleFile2] = useState<File | null>(null)
  const [cFile, setCFile] = useState<File | null>(null)
  const [isAnalyzing, setIsAnalyzing] = useState(false)
  const [result, setResult] = useState<string | null>(null)

  const handleFileChange = (
    e: React.ChangeEvent<HTMLInputElement>,
    setter: React.Dispatch<React.SetStateAction<File | null>>
  ): void => {
    if (e.target.files && e.target.files[0]) {
      setter(e.target.files[0])
    }
  }

  const handleStartCheck = async () => {
    if (!cFile || !ruleFile1 || !ruleFile2) {
      alert('すべてのファイルをアップロードしてください。')
      return
    }

    setIsAnalyzing(true)
    setResult(null)

    try {
      const readFileAsArrayBuffer = (file: File): Promise<ArrayBuffer> => {
        return new Promise((resolve, reject) => {
          const reader = new FileReader()
          reader.onload = () => resolve(reader.result as ArrayBuffer)
          reader.onerror = (error) => reject(error)
          reader.readAsArrayBuffer(file)
        })
      }

      const [cFileContent, rule1Content, rule2Content] = await Promise.all([
        readFileAsArrayBuffer(cFile),
        readFileAsArrayBuffer(ruleFile1),
        readFileAsArrayBuffer(ruleFile2)
      ])

      const analysisResult = await window.electronAPI.analyzeCode({ cFileContent, rule1Content, rule2Content })
      setResult(analysisResult)
    } catch (error) {
      console.error('解析中にエラーが発生しました:', error)
      alert('解析中にエラーが発生しました。')
    } finally {
      setIsAnalyzing(false)
    }
  }

  return (
    <div className="container">
      <h1 className="title">C言語コーディング規約チェッカー</h1>

      <div className="upload-section">
        <label htmlFor="rule1-upload" className="upload-button">
          規約その1をアップ
        </label>
        <input
          id="rule1-upload"
          type="file"
          accept=".txt"
          style={{ display: 'none' }}
          onChange={(e): void => handleFileChange(e, setRuleFile1)}
        />
        {ruleFile1 && <span className="file-name">選択されたファイル: {ruleFile1.name}</span>}
      </div>

      <div className="upload-section">
        <label htmlFor="rule2-upload" className="upload-button">
          規約その2をアップ
        </label>
        <input
          id="rule2-upload"
          type="file"
          accept=".txt"
          style={{ display: 'none' }}
          onChange={(e): void => handleFileChange(e, setRuleFile2)}
        />
        {ruleFile2 && <span className="file-name">選択されたファイル: {ruleFile2.name}</span>}
      </div>

      <div className="upload-section">
        <label htmlFor="cfile-upload" className="upload-button">
          C言語ファイルをアップ
        </label>
        <input
          id="cfile-upload"
          type="file"
          accept=".c"
          style={{ display: 'none' }}
          onChange={(e): void => handleFileChange(e, setCFile)}
        />
        {cFile && <span className="file-name">選択されたファイル: {cFile.name}</span>}
      </div>

      <div className="action-section">
        <button
          className="action-button"
          onClick={handleStartCheck}
          disabled={!ruleFile1 || !ruleFile2 || !cFile || isAnalyzing}
        >
          {isAnalyzing ? '解析中...' : 'チェックを開始'}
        </button>
      </div>
      {result && <div className="result-section">解析結果: <pre>{result}</pre></div>}
    </div>
  )
}

export default App