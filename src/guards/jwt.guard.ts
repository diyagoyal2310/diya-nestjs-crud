import {CanActivate, ExecutionContext, Injectable} from "@nestjs/common";
import { Reflector } from '@nestjs/core';
import { JWT_HEADER_PARAM, verifyJWT } from '../shared/utils';
import { IS_PUBLIC_KEY } from '../shared/public.decorator';

@Injectable()
export class JWTGuard implements CanActivate {

    constructor(private readonly reflector: Reflector) {}

    canActivate(context: ExecutionContext): boolean {

        const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);

        if (isPublic) {
            return true;
        }

        const request = context.switchToHttp().getRequest();

        const jwtTokenRequest = request.headers[JWT_HEADER_PARAM] || null;

        if (!jwtTokenRequest) {
            return false;
        }

        
        return verifyJWT(jwtTokenRequest);
    }
}
