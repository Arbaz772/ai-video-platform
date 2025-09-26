import React, { useState, useEffect } from 'react';

export default function Home(){
  const [prompt, setPrompt] = useState('');
  const [jobId, setJobId] = useState(null);
  const [status, setStatus] = useState(null);
  const [videoUrl, setVideoUrl] = useState(null);
  const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

  useEffect(() => {
    if(!jobId) return;
    const i = setInterval(async ()=>{
      const r = await fetch(`${API}/job/${jobId}`);
      if(r.ok){
        const j = await r.json();
        setStatus(j.status);
        if(j.videoUrl){
          setVideoUrl(j.videoUrl);
          clearInterval(i);
        }
      } else {
        clearInterval(i);
      }
    }, 2000);
    return () => clearInterval(i);
  }, [jobId]);

  async function handleGenerate(){
    setStatus('submitting');
    const r = await fetch(`${API}/generate`, {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({ prompt, durationMinutes:1 })
    });
    const j = await r.json();
    if(j.jobId) setJobId(j.jobId);
    else alert('Error: '+JSON.stringify(j));
  }

  return (
    <div style={{maxWidth:800, margin:'24px auto', fontFamily:'Arial, sans-serif'}}>
      <h1>AI Video Generator — UI (Local Mock)</h1>
      <textarea value={prompt} onChange={e=>setPrompt(e.target.value)} rows={6} style={{width:'100%'}} placeholder="Describe the video..."></textarea>
      <div style={{marginTop:8}}>
        <button onClick={handleGenerate} disabled={!prompt}>Generate (Mock)</button>
      </div>
      <div style={{marginTop:20}}>
        <strong>Job:</strong> {jobId || '-' } <br/>
        <strong>Status:</strong> {status || '-'}
      </div>
      {videoUrl && (
        <div style={{marginTop:20}}>
          <h3>Result</h3>
          <video controls src={videoUrl} style={{maxWidth:'100%'}} />
        </div>
      )}
    </div>
  );
}
