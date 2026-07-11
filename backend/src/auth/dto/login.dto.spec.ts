import { ArgumentMetadata, BadRequestException, ValidationPipe } from '@nestjs/common';
import { LoginDto } from './login.dto';

describe('LoginDto validation', () => {
  const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });
  const metadata: ArgumentMetadata = { type: 'body', metatype: LoginDto, data: '' };

  it('rejects an invalid email', async () => {
    await expect(
      pipe.transform({ email: 'not-an-email', password: 'secret' }, metadata),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects an empty password', async () => {
    await expect(
      pipe.transform({ email: 'user@example.com', password: '' }, metadata),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects extra fields not defined on the DTO', async () => {
    await expect(
      pipe.transform({ email: 'user@example.com', password: 'secret', role: 'admin' }, metadata),
    ).rejects.toThrow(BadRequestException);
  });

  it('accepts a valid payload', async () => {
    const result = await pipe.transform({ email: 'user@example.com', password: 'secret' }, metadata);

    expect(result).toBeInstanceOf(LoginDto);
  });
});
