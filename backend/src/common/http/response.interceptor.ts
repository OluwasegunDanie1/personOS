import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { isApiResponse } from './api-response';

interface SuccessEnvelope {
  success: true;
  data: unknown;
  meta?: unknown;
}

@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  intercept(_context: ExecutionContext, next: CallHandler): Observable<SuccessEnvelope> {
    return next.handle().pipe(
      map((result: unknown) => {
        if (isApiResponse(result)) {
          return result.meta === undefined
            ? { success: true, data: result.data }
            : { success: true, data: result.data, meta: result.meta };
        }

        return { success: true, data: result };
      }),
    );
  }
}
