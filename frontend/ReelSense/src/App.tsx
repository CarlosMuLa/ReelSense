import { useState, useRef, useEffect } from 'react'
import toast, { Toaster } from 'react-hot-toast'
import { useMovieSearch } from '../api/useRecomendation'
import './App.css'

function App() {
  const [query, setQuery] = useState('')
  const { mutate, data, isPending } = useMovieSearch();
  const textAreaRef = useRef<HTMLTextAreaElement>(null)
  
  const MAX_CHARS = 1000 
  const MIN_WORDS = 10

  useEffect(() => {
    if (textAreaRef.current) {
      textAreaRef.current.style.height = 'auto'
      textAreaRef.current.style.height = `${textAreaRef.current.scrollHeight}px`
    }
  }, [query])

  const handleSearch = async () => {
    const wordCount = query.trim().split(/\s+/).filter(word => word.length > 0).length
    
    if (wordCount < MIN_WORDS) {
      toast.error(`¡Cuéntame un poco más! Necesito al menos ${MIN_WORDS} palabras para darte una buena recomendación.`, {
        icon: '✍️',
        style: { borderRadius: '10px', background: '#1A1953', color: '#fff' }
      })
      return
    }

    if (query.length > MAX_CHARS) {
      toast.error('El texto es demasiado largo. Intenta resumir un poco para que el modelo lo procese mejor .', {
        icon: '✂️',
        style: { 
          borderRadius: '10px', 
          background: '#1A1953', 
          color: '#fff' 
        }
      })
      return
    }

    toast.success('Buscando las mejores películas para ti...', { 
      icon: '🍿' , 
      style: { 
        borderRadius: '10px', 
        background: '#1A1953', 
        color: '#fff' }})
    mutate({ query, mode: 'hybrid' })
    console.log("Iniciando búsqueda de embedding...")

  }

  return (
    <div className={data || isPending ? "container-with-results" : "landing-container"}>
      <Toaster position="bottom-center" reverseOrder={false} />

      <div className="github-logo-container" style={{ position: 'absolute', top: '20px', left: '50%', transform: 'translateX(-50%)', zIndex: 1000 }}>
        <a href="https://github.com/CarlosMuLa/ReelSense" target="_blank" rel="noopener noreferrer" style={{ display: 'block', opacity: 0.8, color: 'inherit' }}>
          <svg height="32" viewBox="0 0 16 16" width="32" fill="currentColor">
            <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"></path>
          </svg>
        </a>
      </div>
      
      <textarea 
        ref={textAreaRef}
        className="landing-input auto-grow" 
        placeholder="¿Qué tipo de película quieres ver?" 
        value={query}
        rows={1}
        onChange={(e) => setQuery(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            if (!isPending) {
              handleSearch();
            }
          }
        }}
      />
      
      <button 
        type="button" 
        className="landing-button"
        onClick={handleSearch}
        disabled={isPending}
      >
        {isPending ? <div className="spinner"></div> : 'Buscar'}
      </button>

      {(data || isPending) && (
        <div className="results-container">
          <div className="results-grid">
            {isPending ? (
              Array.from({ length: 10 }).map((_, index) => (
                <div key={index} className="movie-card skeleton-card">
                  <div className="skeleton-img"></div>
                  <div className="skeleton-text skeleton-title"></div>
                  <div className="skeleton-text skeleton-score"></div>
                </div>
              ))
            ) : data ? (
              data.map(movie => {
                const letterboxdName = movie.name.toLowerCase().replace(/ /g, '-').replace(/[^a-z0-9-]/g, '');
                return (
                  <div key={movie.movie_id} className="movie-card">
                    <a href={`https://letterboxd.com/film/${letterboxdName}/`} target="_blank" rel="noopener noreferrer">
                      <img src={movie.poster} alt={movie.name} />
                    </a>
                    <h3>{movie.name}</h3>
                    <p>{Math.round(movie.score * 100)}% match</p>
                  </div>
                )
              })
            ) : null}
          </div>
        </div>
      )}
    </div>
  )
}

export default App