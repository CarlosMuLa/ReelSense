import { useMutation } from '@tanstack/react-query';

interface SearchParams {
    query: string;
    mode?: string;
}

interface Movie {
    movie_id: number;
    name: string;
    poster: string;
    score: number;
}

const API_URL = 'https://8n18enkmwa.execute-api.us-east-1.amazonaws.com/Reelsense';

export const useMovieSearch = () => {
    return useMutation<Movie[], Error, SearchParams>({
        mutationFn: async ({ query, mode = 'hybrid' }: SearchParams) => {
            const params = new URLSearchParams({ query, mode });
            const response = await fetch(`${API_URL}?${params}`, {
                method: 'GET',
            });
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        }
    });
}