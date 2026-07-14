import { ArgumentMetadata, BadRequestException, ValidationPipe } from '@nestjs/common';
import { RegisterDto } from './register.dto';

describe('RegisterDto validation', () => {
  const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });
  const metadata: ArgumentMetadata = { type: 'body', metatype: RegisterDto, data: '' };

  const validPayload = { firstName: 'Grace', lastName: 'Hopper', email: 'grace@example.com', password: 'secret123' };

  it('accepts a valid payload', async () => {
    const result = await pipe.transform(validPayload, metadata);
    expect(result).toBeInstanceOf(RegisterDto);
  });

  it('trims firstName and lastName', async () => {
    const result = (await pipe.transform(
      { ...validPayload, firstName: '  Grace  ', lastName: '  Hopper  ' },
      metadata,
    )) as RegisterDto;

    expect(result.firstName).toBe('Grace');
    expect(result.lastName).toBe('Hopper');
  });

  it('rejects an empty firstName', async () => {
    await expect(pipe.transform({ ...validPayload, firstName: '' }, metadata)).rejects.toThrow(BadRequestException);
  });

  it('rejects an invalid email', async () => {
    await expect(pipe.transform({ ...validPayload, email: 'not-an-email' }, metadata)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('rejects a password shorter than 8 characters', async () => {
    await expect(pipe.transform({ ...validPayload, password: 'short' }, metadata)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('rejects extra fields not defined on the DTO', async () => {
    await expect(pipe.transform({ ...validPayload, role: 'admin' }, metadata)).rejects.toThrow(BadRequestException);
  });
});
