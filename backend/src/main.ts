import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ResponseInterceptor } from './common/http/response.interceptor';
import { GlobalExceptionFilter } from './common/http/global-exception.filter';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api/v1');
  app.useGlobalInterceptors(new ResponseInterceptor());
  app.useGlobalFilters(new GlobalExceptionFilter());

  // Local development fallback only; production environments must set PORT explicitly.
  const port = process.env.PORT ?? 3000;

  await app.listen(port);
}

bootstrap();
