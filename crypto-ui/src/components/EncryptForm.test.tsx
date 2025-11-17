import { render, screen, fireEvent, waitFor } from "@testing-library/react"
import { describe, it, expect, vi, beforeEach } from "vitest"
import EncryptForm from "./EncryptForm"

describe("EncryptForm Component", () => {
  const mockOnChange = vi.fn()
  const mockOnSubmit = vi.fn()
  const mockWriteText = vi.fn()

  beforeEach(() => {
    vi.resetAllMocks()
    // Simula a API do clipboard
    Object.assign(navigator, {
      clipboard: {
        writeText: mockWriteText,
      },
    })
  })

  it("deve renderizar o título e o campo de texto corretamente", () => {
    render(
      <EncryptForm
        payload=""
        onChange={mockOnChange}
        onSubmit={mockOnSubmit}
        loading={false}
        result={null}
      />
    )

    expect(screen.getByText("Criptografar com AES 256 GCM")).toBeInTheDocument()
    expect(
      screen.getByLabelText("Digite o texto que deseja criptografar:")
    ).toBeInTheDocument()
  })

  it("deve chamar onChange quando o usuário digitar no textarea", () => {
    render(
      <EncryptForm
        payload=""
        onChange={mockOnChange}
        onSubmit={mockOnSubmit}
        loading={false}
        result={null}
      />
    )

    const textarea = screen.getByPlaceholderText("Ex: Texto a ser criptografado...")
    fireEvent.change(textarea, { target: { value: "Teste de criptografia" } })
    expect(mockOnChange).toHaveBeenCalledWith("Teste de criptografia")
  })

  it("deve chamar onSubmit ao clicar em 'Criptografar'", () => {
    render(
      <EncryptForm
        payload="algum texto"
        onChange={mockOnChange}
        onSubmit={mockOnSubmit}
        loading={false}
        result={null}
      />
    )

    const button = screen.getByRole("button", { name: "Criptografar" })
    fireEvent.click(button)
    expect(mockOnSubmit).toHaveBeenCalledTimes(1)
  })

  it("deve exibir o resultado e permitir copiar o texto", async () => {
    render(
      <EncryptForm
        payload="teste"
        onChange={mockOnChange}
        onSubmit={mockOnSubmit}
        loading={false}
        result="Texto criptografado: abc123"
      />
    )

    expect(screen.getByText("Resultado da Criptografia:")).toBeInTheDocument()
    expect(screen.getByText("Texto criptografado: abc123")).toBeInTheDocument()

    const copyButton = screen.getByRole("button", { name: "Copiar resultado" })
    fireEvent.click(copyButton)

    await waitFor(() => expect(mockWriteText).toHaveBeenCalledWith("Texto criptografado: abc123"))
    await waitFor(() => expect(screen.getByText("Copiado!")).toBeInTheDocument())
  })
})
