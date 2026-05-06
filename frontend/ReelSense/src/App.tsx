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
    <div className={data ? "container-with-results" : "landing-container"}>
      <Toaster position="bottom-center" reverseOrder={false} />
      
      <textarea 
        ref={textAreaRef}
        className="landing-input auto-grow" 
        placeholder="¿Qué tipo de película quieres ver?" 
        value={query}
        rows={1}
        onChange={(e) => setQuery(e.target.value)}
      />
      
      <button 
        type="button" 
        className="landing-button"
        onClick={handleSearch}
        disabled={isPending}
      >
        {isPending ? 'Buscando...' : 'Buscar'}
      </button>

      {data && (
        <div className="results-container">
          <div className="results-grid">
            {data.map(movie => {
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
            })}
          </div>
        </div>
      )}
    </div>
  )
}

export default App