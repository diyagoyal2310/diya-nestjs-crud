import * as jwt from 'jsonwebtoken';

export const NOT_ALLOWED_USER_MESSAGE= 'Action not allowed for this user';
export const JWT_HEADER_PARAM= 'x-jwt-assertion';

interface JwtPayloadWithUid extends jwt.JwtPayload {
    uid: string;
}

const getJwtSecret = (): string => {
    const secret = process.env.JWT_SECRET;

    if (!secret || secret.length < 32) {
        throw new Error('JWT_SECRET must be set and contain at least 32 characters');
    }

    return secret;
};

const getVerifiedJwtPayload = (encodedJWT: string): JwtPayloadWithUid => {
    const decoded = jwt.decode(encodedJWT, { complete: true });

    if (!decoded || decoded.header.typ !== 'JWT' || decoded.header.alg !== 'HS256') {
        throw new Error('Invalid JWT header');
    }

    const payload = jwt.verify(encodedJWT, getJwtSecret(), {
        algorithms: ['HS256'],
    });

    if (typeof payload === 'string' || !payload.uid || typeof payload.uid !== 'string') {
        throw new Error('JWT uid claim is required');
    }

    return payload as JwtPayloadWithUid;
};

export const verifyJWT = (encodedJWT) => {
    try{
        getVerifiedJwtPayload(encodedJWT);
        return true;

    }catch (e) {
        return false;
    }
};

export const getJWTUser = (encodedJWT) => {
    try{
        return getVerifiedJwtPayload(encodedJWT).uid;

    }catch (e) {
        return null;
    }
};

export const userCanDoAction = (token, username) => {
    try{
        return (getJWTUser(token).toLowerCase() === username.toLowerCase());

    }catch (e) {
        return false;
    }
};
