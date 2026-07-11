import { CallHandler, ExecutionContext } from '@nestjs/common';
import { of } from 'rxjs';
import { ApiResponse } from './api-response';
import { ResponseInterceptor } from './response.interceptor';

function handlerReturning(value: unknown): CallHandler {
  return { handle: () => of(value) };
}

describe('ResponseInterceptor', () => {
  const interceptor = new ResponseInterceptor();
  const context = {} as ExecutionContext;

  it('wraps a plain controller result as success/data', (done) => {
    interceptor.intercept(context, handlerReturning({ id: '1' })).subscribe((result) => {
      expect(result).toEqual({ success: true, data: { id: '1' } });
      done();
    });
  });

  it('wraps an explicit ApiResponse.withMeta result as success/data/meta', (done) => {
    const value = ApiResponse.withMeta([{ id: '1' }], { total: 1 });

    interceptor.intercept(context, handlerReturning(value)).subscribe((result) => {
      expect(result).toEqual({
        success: true,
        data: [{ id: '1' }],
        meta: { total: 1 },
      });
      done();
    });
  });

  it('wraps an explicit ApiResponse.of result as success/data only', (done) => {
    const value = ApiResponse.of({ id: '1' });

    interceptor.intercept(context, handlerReturning(value)).subscribe((result) => {
      expect(result).toEqual({ success: true, data: { id: '1' } });
      done();
    });
  });

  it('treats a business object with an ordinary "meta" property as plain data', (done) => {
    const businessData = { id: '1', meta: 'not an envelope' };

    interceptor.intercept(context, handlerReturning(businessData)).subscribe((result) => {
      expect(result).toEqual({ success: true, data: businessData });
      done();
    });
  });

  it('does not double-wrap an ApiResponse result', (done) => {
    const value = ApiResponse.of({ id: '1' });

    interceptor.intercept(context, handlerReturning(value)).subscribe((result) => {
      expect((result as { data: unknown }).data).not.toHaveProperty('success');
      done();
    });
  });
});
