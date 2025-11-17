import { render, screen, fireEvent, waitFor } from "@testing-library/react"
import { describe, it, expect, vi, beforeEach } from "vitest"
import DecryptForm from "./DecryptForm"

describe("DecryptForm Component", () => {
  const mockOnChange = vi.fn()
  const mockOnSubmit = vi.fn()
  const mockWriteText = vi.fn()

  beforeEach(() => {
    vi.resetAllMocks()
    // simula a API do clipboard
    Object.assign(navigator, {
      clipboard: {
        writeText: mockWriteText,
      },
    })
  })

  it("deve renderizar corretamente o título e textarea", () => {
    render(
      <DecryptForm
        payload=""
        onChange={mockOnChange}
        onSubmit={mockOnSubmit}
        loading={false}
        result={null}
      />
    )

    expect(
      screen.getByText("Descriptografar com AES 256 GCM")
    ).toBeInTheDocument()

    expect(
      screen.getByLabelText("Digite o texto criptografado:")
    ).toBeInTheDocument()
  })

  it("deve chamar onChange ao digitar no campo", () => {
    render(
      <DecryptForm
        payload=""
        onChange={mockOnChange}
        onSubmit={mockOnSubmit}
        loading={false}
        result={null}
      />
    )

    const textarea = screen.getByPlaceholderText(
      "Ex: Ciphertext recebido da API..."
    )
    fireEvent.change(textarea, { target: { value: "mensagem criptografada" } })
    expect(mockOnChange).toHaveBeenCalledWith("mensagem criptografada")
  })

  it("deve chamar onSubmit ao clicar em 'Descriptografar'", () => {
    render(
      <DecryptForm
        payload="abc123"
        onChange={mockOnChange}
        onSubmit={mockOnSubmit}
        loading={false}
        result={null}
      />
    )

    const button = screen.getByRole("button", { name: /Descriptografar/i })
    fireEvent.click(button)
    expect(mockOnSubmit).toHaveBeenCalledTimes(1)
  })

  it("deve exibir o resultado e permitir copiar o texto", async () => {
    render(
      <DecryptForm
        payload="xyz"
        onChange={mockOnChange}
        onSubmit={mockOnSubmit}
        loading={false}
        result="Texto descriptografado: Olá Mundo!"
      />
    )

    expect(
      screen.getByText("Resultado da Descriptografia")
    ).toBeInTheDocument()

    expect(
      screen.getByText("Texto descriptografado: Olá Mundo!")
    ).toBeInTheDocument()

    const copyButton = screen.getByRole("button", { name: /Copiar resultado/i })
    fireEvent.click(copyButton)

    await waitFor(() =>
      expect(mockWriteText).toHaveBeenCalledWith(
        "Texto descriptografado: Olá Mundo!"
      )
    )

    await waitFor(() =>
      expect(screen.getByText("Copiado!")).toBeInTheDocument()
    )
  })
})
