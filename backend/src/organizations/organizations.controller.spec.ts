import { AuthenticatedRequest } from '../common/http/request-context';
import { OrganizationsController } from './organizations.controller';

describe('OrganizationsController', () => {
  it('delegates to OrganizationsService using request.auth.userId only', async () => {
    const service = { listForUser: jest.fn().mockResolvedValue({ organizations: [] }) };
    const controller = new OrganizationsController(service as never);
    const request = {
      headers: {},
      params: {},
      auth: { userId: 'user-1' },
    } as AuthenticatedRequest & { query?: unknown; body?: unknown };
    // Simulate a client attempting to smuggle a different userId via other
    // request channels; the controller must never read these.
    request.query = { userId: 'attacker-supplied-id' };
    request.body = { userId: 'attacker-supplied-id' };

    const result = await controller.list(request);

    expect(service.listForUser).toHaveBeenCalledWith('user-1');
    expect(service.listForUser).not.toHaveBeenCalledWith('attacker-supplied-id');
    expect(result).toEqual({ organizations: [] });
  });
});
