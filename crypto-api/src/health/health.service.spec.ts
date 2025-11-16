import { Test, TestingModule } from '@nestjs/testing';
import { HealthService } from './health.service';

describe('HealthService', () => {
  let service: HealthService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [HealthService],
    }).compile();

    service = module.get<HealthService>(HealthService);
  });

  it('deve ser definido', () => {
    expect(service).toBeDefined();
  });

  it('deve retornar status OK e timestamp válido', () => {
    const result = service.checkStatus();

    expect(result).toBeDefined();
    expect(result.status).toBe('OK');

    // Verifica se o timestamp é uma string válida ISO 8601
    expect(typeof result.timestamp).toBe('string');
    const date = new Date(result.timestamp);
    expect(date.toISOString()).toBe(result.timestamp);
  });

  it('deve gerar timestamps diferentes em chamadas subsequentes', () => {
    const result1 = service.checkStatus();
    const result2 = service.checkStatus();

    const date1 = new Date(result1.timestamp);
    const date2 = new Date(result2.timestamp);

    // Garante que a segunda chamada não é antes da primeira
    expect(date2.getTime()).toBeGreaterThanOrEqual(date1.getTime());
  });

  it('deve retornar objetos independentes em chamadas subsequentes', () => {
    const result1 = service.checkStatus();
    const result2 = service.checkStatus();

    // Garante que não são a mesma referência
    expect(result1).not.toBe(result2);

    // Garante que o conteudo status é igual
    expect(result1.status).toBe(result2.status);

    // Mas os timestamps são diferentes ou iguais em ordem cronológica
    expect(new Date(result2.timestamp).getTime()).toBeGreaterThanOrEqual(
      new Date(result1.timestamp).getTime(),
    );
  });
});
