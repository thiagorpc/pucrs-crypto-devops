interface HeaderProps {
  loading: boolean;
  onCheckHealth: () => void;
}

export default function Header({ loading, onCheckHealth }: HeaderProps) {
  return (
    <header className="bg-blue-700 text-white shadow-lg fixed top-0 left-0 w-full z-10">
      <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold">🔒 Serviço de Criptografia</h1>
        <button
          onClick={onCheckHealth}
          className="text-sm border border-white/50 hover:bg-white/10 p-2 rounded transition-colors disabled:opacity-50"
          disabled={loading}
        >
          {loading ? "Testando..." : "Status API"}
        </button>
      </div>
    </header>
  );
}
