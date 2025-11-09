import { useState } from "react";
import { encryptData, getHealth } from "./api"; // Presume a existência do módulo api.ts

function App() {
  const [health, setHealth] = useState<any>(null);
  const [payload, setPayload] = useState("");
  // Alterado para 'hash' ou 'result' para refletir a operação de hash Argon2
  const [result, setResult] = useState<string>(""); 
  const [loading, setLoading] = useState(false);

  // --- Funções de API (mantidas) ---

  const fetchHealth = async () => {
    setLoading(true);
    try {
      const data = await getHealth();
      setHealth(data);
    } catch (err) {
      console.error(err);
      setHealth({ error: "Falha ao acessar API" });
    } finally {
      setLoading(false);
    }
  };

  const handleHash = async () => {
    if (!payload) return alert("Digite algum texto");
    setLoading(true);
    // Assumindo que a API de Criptografia fará Hash (Argon2), não criptografia simétrica
    try {
      // NOTE: Ajuste a função da API de acordo com seu backend (e.g., hashData)
      const data = await encryptData(payload); 
      setResult(data.hash || JSON.stringify(data)); // Espera 'hash' da API
    } catch (err) {
      console.error(err);
      setResult("Erro ao gerar Hash / Criptografar");
    } finally {
      setLoading(false);
    }
  };

  // --- Renderização com Tailwind ---

  return (
    // min-h-screen: Garante que ocupe pelo menos 100% da altura da viewport.
    <div className="min-h-screen bg-gray-100 flex flex-col">
      
      {/* 🔷 Barra Superior */}
      <header className="bg-blue-700 text-white shadow-lg fixed top-0 left-0 w-full z-10">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <h1 className="text-3xl font-bold">Crypto Service UI 🔑</h1>
          <button 
             onClick={fetchHealth}
             className="text-sm border border-white/50 hover:bg-white/10 p-2 rounded transition-colors disabled:opacity-50"
             disabled={loading}
          >
             {loading ? "Testando..." : "Status API"}
          </button>
        </div>
      </header>
      
      {/* 🔹 Conteúdo Principal: pt-20 evita que o conteúdo fique atrás do header fixo */}
      <main className="max-w-7xl mx-auto px-6 pt-20 pb-10 flex-grow space-y-8 w-full">
        
        {/* Seção Status/Health Check (Trocada para ser um modal ou aviso) */}
        {health && (
          <div className={`p-4 rounded-lg shadow-md transition-all duration-300 ${health.error ? 'bg-red-100 border border-red-400' : 'bg-green-100 border border-green-400'}`}>
            <h3 className="font-semibold text-lg mb-2">
                {health.error ? "❌ API OFFLINE" : "✅ API ONLINE"}
            </h3>
            <pre className="bg-white p-3 rounded text-xs overflow-x-auto text-gray-700">
              {JSON.stringify(health, null, 2)}
            </pre>
          </div>
        )}

        {/* 🔐 Seção Criptografia/Hash */}
        <section className="bg-white p-8 rounded-xl shadow-2xl">
          <h2 className="text-2xl font-extrabold text-gray-700 mb-6 border-b pb-2">
            Função de Hash (Argon2)
          </h2>
          
          <div className="space-y-6">
            <label htmlFor="payload" className="block text-gray-700 font-medium">
                Digite a string para hash/criptografar:
            </label>
            <input
              id="payload"
              type="text"
              value={payload}
              onChange={(e) => setPayload(e.target.value)}
              placeholder="Ex: Minha senha secreta..."
              className="w-full border border-gray-300 rounded-lg px-4 py-3 text-lg focus:outline-none focus:ring-4 focus:ring-blue-200 transition-shadow"
            />
            
            <button
              onClick={handleHash}
              disabled={loading || !payload}
              className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 disabled:cursor-not-allowed text-white font-bold py-3 rounded-lg text-lg shadow-md hover:shadow-lg transition-all"
            >
              {loading ? "Gerando Hash..." : "Gerar Hash com Argon2"}
            </button>
          </div>

          {result && (
            <div className="mt-8">
              <h3 className="text-xl font-semibold mb-3 text-gray-700">Resultado do Hash:</h3>
              <pre className="bg-gray-800 text-green-400 p-6 rounded-lg text-sm overflow-x-auto whitespace-pre-wrap break-all shadow-inner">
                {result}
              </pre>
            </div>
          )}
        </section>
        
      </main>
      
      {/* 🦶 Footer (Adicionado para completar a página) */}
      <footer className="bg-gray-200 mt-8 py-4 text-center text-sm text-gray-500">
          <p>PUCRS DevOps Case Study | Backend: NestJS (Argon2) | Frontend: React/Vite</p>
      </footer>
    </div>
  );
}

export default App;