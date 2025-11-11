import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT', 3000);
  const host = configService.get<string>('HOST', 'localhost');

  const corsOriginsString = [
    'http://localhost:5173',
    'https://crypto-api-alb-1701207900.us-east-1.elb.amazonaws.com/health',
    'http://crypto-api-alb-1701207900.us-east-1.elb.amazonaws.com/health',
    'https://pucrs-crypto-ui.s3.us-east-1.amazonaws.com/',
    'http://pucrs-crypto-ui.s3.us-east-1.amazonaws.com/',
  ];

  // Habilita CORS
  app.enableCors({
    origin: [corsOriginsString],
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  await app.listen(port, host);

  const logger = new Logger('Bootstrap');
  logger.log(`🚀 API...... rodando em http://${host}:${port}`);
}

void bootstrap();
