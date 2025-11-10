import { useState } from "react";
import { decryptData, encryptData, getHealth } from "./api";

import DecryptForm from "./components/DecryptForm";
import EncryptForm from "./components/EncryptForm";
import Footer from "./components/Footer";
import Header from "./components/Header";
import HealthCheck from "./components/HealthCheck";

interface Health { status?: string; error?: string }

export default function App() {
  const [health, setHealth] = useState<Health | null>(null);
  const [payload, setPayload] = useState("");
  const [payloadEncryptData, setPayloadEncryptData] = useState("");
  const [encryptedResult, setEncryptedResult] = useState<string | null>(null);
  const [decryptedResult, setDecryptedResult] = useState<string | null>(null);

  const [loadingEncrypt, setLoadingEncrypt] = useState(false);
  const [loadingDecrypt, setLoadingDecrypt] = useState(false);
  const [loadingHealth, setLoadingHealth] = useState(false);
  const [showHealth, setShowHealth] = useState(false); // <--- novo

  const fetchHealth = async () => {
    setLoadingHealth(true);
    try {
      const data = await getHealth();
      setHealth(data);
      setShowHealth(true); // mostra o HealthCheck
    } catch (err) {
      console.error(err);
      setHealth({ error: "Falha ao acessar API" });
      setShowHealth(true);
    } finally {
      setLoadingHealth(false);
    }
  };

  const handleEncrypt = async () => {
    if (!payload) return;
    setLoadingEncrypt(true);
    try {
      const data = await encryptData(payload);
      setEncryptedResult(data.encrypted || "Erro ao gerar criptografia");
    } catch (err) {
      console.error(err);
      setEncryptedResult(null);
      alert("Erro ao criptografar");
    } finally {
      setLoadingEncrypt(false);
    }
  };

  const handleDecrypt = async () => {
    if (!payloadEncryptData) return;
    setLoadingDecrypt(true);
    try {
      const data = await decryptData(payloadEncryptData);
      setDecryptedResult(data.decrypted || "Erro ao descriptografar");
    } catch (err) {
      console.error(err);
      setDecryptedResult(null);
      alert("Erro ao descriptografar");
    } finally {
      setLoadingDecrypt(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col">
      <Header loading={loadingHealth} onCheckHealth={fetchHealth} />

      <main className="max-w-7xl mx-auto px-6 pt-0 pb-5 flex-grow space-y-8 w-full">
        <HealthCheck
          health={health}
          show={showHealth}
          onClose={() => setShowHealth(false)}
        />

        <EncryptForm
          payload={payload}
          onChange={setPayload}
          onSubmit={handleEncrypt}
          loading={loadingEncrypt}
          result={encryptedResult}
        />

        <DecryptForm
          payload={payloadEncryptData}
          onChange={setPayloadEncryptData}
          onSubmit={handleDecrypt}
          loading={loadingDecrypt}
          result={decryptedResult}
        />
      </main>

      <Footer />
    </div>
  );
}
