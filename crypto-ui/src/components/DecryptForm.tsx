interface DecryptFormProps {
  payload: string;
  onChange: (value: string) => void;
  onSubmit: () => void;
  loading: boolean;
  result: string | null;
}

export default function DecryptForm({ payload, onChange, onSubmit, loading, result }: DecryptFormProps) {
  return (
    <section className="bg-white p-8 rounded-xl shadow-2xl">
      <h2 className="text-2xl font-extrabold text-gray-700 mb-6 border-b pb-2">
        Descriptografar com AES 256 GCM
      </h2>

      <div className="space-y-6">
        <label htmlFor="payloadEncryptData" className="block text-gray-700 font-medium">
          Digite o texto criptografado:
        </label>
        <input
          id="payloadEncryptData"
          type="text"
          value={payload}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Ex: Ciphertext recebido da API..."
          className="w-full border border-gray-300 rounded-lg px-4 py-3 text-lg focus:outline-none focus:ring-4 focus:ring-blue-200 transition-shadow"
        />
        <button
          onClick={onSubmit}
          disabled={loading || !payload}
          className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 disabled:cursor-not-allowed text-white font-bold py-3 rounded-lg text-lg shadow-md hover:shadow-lg transition-all"
        >
          {loading ? "Aguarde..." : "Descriptografar Texto"}
        </button>
      </div>

      {result && (
        <div className="mt-8">
          <h3 className="text-xl font-semibold mb-3 text-gray-700">Resultado da Descriptografia:</h3>
          <pre className="bg-gray-800 text-green-400 p-6 rounded-lg text-sm overflow-x-auto whitespace-pre-wrap break-all shadow-inner">
            {result}
          </pre>
        </div>
      )}
    </section>
  );
}
