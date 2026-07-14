import { ArgumentMetadata, BadRequestException, ValidationPipe } from '@nestjs/common';
import { ForgotPasswordDto } from './forgot-password.dto';

describe('ForgotPasswordDto validation', () => {
  const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });
  const metadata: ArgumentMetadata = { type: 'body', metatype: ForgotPasswordDto, data: '' };

  it('accepts a valid email', async () => {
    const result = await pipe.transform({ email: 'user@example.com' }, metadata);
    expect(result).toBeInstanceOf(ForgotPasswordDto);
  });

  it('rejects an invalid email', async () => {
    await expect(pipe.transform({ email: 'not-an-email' }, metadata)).rejects.toThrow(BadRequestException);
  });

  it('rejects extra fields not defined on the DTO', async () => {
    await expect(pipe.transform({ email: 'user@example.com', userId: 'attacker' }, metadata)).rejects.toThrow(
      BadRequestException,
    );
  });
});
