/**
 * Explicit marker for a controller result that carries approved response
 * metadata (e.g. pagination). Using a class (not duck-typed object shape)
 * prevents ordinary business data that happens to contain a "meta" property
 * from being mistaken for envelope metadata.
 */
export class ApiResponse<T> {
  private constructor(
    public readonly data: T,
    public readonly meta?: unknown,
  ) {}

  static of<T>(data: T): ApiResponse<T> {
    return new ApiResponse(data);
  }

  static withMeta<T>(data: T, meta: unknown): ApiResponse<T> {
    return new ApiResponse(data, meta);
  }
}

export function isApiResponse(value: unknown): value is ApiResponse<unknown> {
  return value instanceof ApiResponse;
}
