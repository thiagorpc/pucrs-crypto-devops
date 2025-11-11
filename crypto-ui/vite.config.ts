import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import { defineConfig, loadEnv } from 'vite';

export default ({ mode }) => {
  // Carrega as variáveis de ambiente de acordo com o modo (development, production, etc.)
  const env = loadEnv(mode, process.cwd(), '');

  return defineConfig({
    plugins: [tailwindcss(), react()],
    server: {
      proxy: {
        '/api': {
          target: env.VITE_API_URL || 'https://localhost:3000',
          changeOrigin: true,
          secure: false, // ignora certificado autoassinado
        },
      },
    },
  });
};