import { Transform } from 'class-transformer';
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

function trim({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class RegisterDto {
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  firstName!: string;

  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  lastName!: string;

  @IsEmail()
  email!: string;

  // No specific numeric password policy is documented anywhere in this
  // repository; 8 characters is applied as the minimum conservative,
  // industry-standard baseline (16_Security.md requires "the approved
  // password policy" be enforced but states no exact number).
  @IsString()
  @MinLength(8)
  password!: string;
}
