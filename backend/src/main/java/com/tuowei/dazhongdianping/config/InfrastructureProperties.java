package com.tuowei.dazhongdianping.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.infrastructure")
public class InfrastructureProperties {

    private StateStore stateStore = new StateStore();

    public StateStore getStateStore() {
        return stateStore;
    }

    public void setStateStore(StateStore stateStore) {
        this.stateStore = stateStore;
    }

    public enum StateStoreProvider {
        LOCAL,
        REDIS
    }

    public static class StateStore {

        private StateStoreProvider provider = StateStoreProvider.LOCAL;
        private String keyPrefix = "dzdp";

        public StateStoreProvider getProvider() {
            return provider;
        }

        public void setProvider(StateStoreProvider provider) {
            this.provider = provider;
        }

        public String getKeyPrefix() {
            return keyPrefix;
        }

        public void setKeyPrefix(String keyPrefix) {
            this.keyPrefix = keyPrefix;
        }
    }
}
