interface HealthCheckProps {
  health: { status?: string; error?: string } | null;
}

export default function HealthCheck({ health }: HealthCheckProps) {
  if (!health) return null;

  const isError = !!health.error;

  return (
    <div className={`p-4 rounded-lg shadow-md transition-all duration-300 ${isError ? 'bg-red-100 border border-red-400' : 'bg-green-100 border border-green-400'}`}>
      <h3 className="font-semibold text-lg mb-2">
        {isError ? "❌ API OFFLINE" : "✅ API ONLINE"}
      </h3>
      <pre className="bg-white p-3 rounded text-xs overflow-x-auto text-gray-700">
        {JSON.stringify(health, null, 2)}
      </pre>
    </div>
  );
}
