import React, { ReactNode } from 'react';
import { AuthProvider as OidcAuthProvider, AuthProviderProps as OidcAuthProviderProps } from 'react-oidc-context';
import keycloakConfig from '../config/keycloak';

interface KeycloakAuthProviderProps {
    children: ReactNode;
}

export const KeycloakAuthProvider: React.FC<KeycloakAuthProviderProps> = ({ children }) => {
    return (
        <OidcAuthProvider {...keycloakConfig}>
            {children}
        </OidcAuthProvider>
    );
};

export default KeycloakAuthProvider;
