import { useState } from "react";
import HealthCheck from "./HealthCheck";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export default function AppHeader({ onCheckHealth, loading, health }: any) {
  const [showHealth, setShowHealth] = useState(false);

  const handleClick = () => {
    onCheckHealth(); // chama a API
    setShowHealth(true); // mostra o card
  };

  return (
    <>
      <header className="bg-blue-700 text-white shadow-lg fixed top-0 left-0 w-full z-10">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold">🔒 Crypto256</h1>
          <button
            onClick={handleClick}
            className="text-sm border border-white/50 hover:bg-white/10 p-2 rounded transition-colors disabled:opacity-50"
            disabled={loading}
          >
            {loading ? "Testando..." : "Status API"}
          </button>
        </div>
      </header>

      <div className="pt-24"> {/* espaço para não ficar atrás do header  */}
        <HealthCheck health={health} show={showHealth} onClose={() => setShowHealth(false)} />
      </div>
    </>
  );
}
