import { LockClosedIcon } from "@heroicons/react/24/solid";
import { useState } from "react";

interface EncryptFormProps {
  payload: string;
  onChange: (value: string) => void;
  onSubmit: () => void;
  loading: boolean;
  result: string | null;
}

function ResultArea({ result }: { result: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(result);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="mt-6 space-y-3">
      <label htmlFor="payload" className="block text-gray-700 font-medium">
        Resultado da Criptografia:
      </label>
      <pre className="bg-gray-100 text-gray-800 p-4 rounded-md text-sm md:text-base overflow-x-auto whitespace-pre-wrap break-all shadow-inner">
        {result}
      </pre>
      <button
        onClick={handleCopy}
        className="w-full md:w-auto px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-md shadow-md transition-all"
      >
        {copied ? "Copiado!" : "Copiar resultado"}
      </button>
    </div>
  );
}

export default function EncryptForm({
  payload,
  onChange,
  onSubmit,
  loading,
  result,
}: EncryptFormProps) {
  return (
    <section className="bg-white p-6 md:p-8 rounded-xl shadow-lg max-w-3xl mx-auto">
      <h2 className="text-2xl md:text-2xl font-extrabold text-gray-700 mb-6 border-b pb-2 flex items-center gap-2">
        <LockClosedIcon className="w-6 h-6 text-orange-500" />
        Criptografar com AES 256 GCM
      </h2>

      <div className="space-y-4">
        <label htmlFor="payload" className="block text-gray-700 font-medium">
          Digite o texto que deseja criptografar:
        </label>

        <textarea
          id="payload"
          value={payload}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Ex: Texto a ser criptografado..."
          className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm md:text-base focus:outline-none focus:ring-4 focus:ring-blue-200 transition-shadow resize-y whitespace-pre-wrap break-all"
          rows={2}
        />

        <button
          onClick={onSubmit}
          disabled={loading || !payload}
          className={`w-full md:w-auto px-4 py-2 text-white font-bold rounded-md shadow-md transition-all ${
            loading || !payload ? "bg-gray-400 cursor-not-allowed" : "bg-orange-500 hover:bg-orange-600"
          }`}
        >
          {loading ? "Aguarde..." : "Criptografar"}
        </button>
      </div>

      {result && <ResultArea result={result} />}
    </section>
  );
}
