FROM adoptopenjdk/openjdk8:x86_64-alpine-jdk8u232-b09
# ------------------------------------------------------
# --- Environments and base directories
ENV ANDROID_HOME="/home/stolas69/sdk/android" \
    FLUTTER_HOME="/home/stolas69/sdk/flutter" \
    GRADLE_HOME="/home/stolas69/tools/gradle" \
    MAVEN_HOME="/home/stolas69/tools/maven" \
    USER_HOME="/home/stolas69"
# ------------------------------------------------------
# --- Install required tools
RUN apk update; \
    apk add --no-cache bash curl git libstdc++ unzip ca-certificates make jq; \
    update-ca-certificates; \
    # --- Configure git
    git config --global user.email "docker@swedspot.com"; \
    git config --global user.name "Docker"
# ------------------------------------------------------
# --- Create user and home directory
RUN adduser -D --shell /bin/bash stolas69
# --- Run the rest of commands as user stolas69
USER stolas69
WORKDIR ${USER_HOME}
# ------------------------------------------------------
# --- Download Android SDK tools into $ANDROID_HOME
RUN set -eux; \
    mkdir -p ${ANDROID_HOME}; \
    ESUM='92ffee5a1d98d856634e8b71132e8a95d96c83a63fde1099be3d86df3106def9'; \
    ARCHIVE='sdk-tools-linux-4333796.zip'; \
    BINARY_URL="https://dl.google.com/android/repository/${ARCHIVE}"; \
    curl -LfsSo ${ARCHIVE} ${BINARY_URL}; \
    echo "${ESUM} *${USER_HOME}/${ARCHIVE}" | sha256sum -c -;\
    unzip -q ${ARCHIVE} -d ${ANDROID_HOME}; \
    rm ${ARCHIVE}; \
    # ------------------------------------------------------
    # --- Install Android SDKs and other build packages
    # Accept licenses before installing components, no need to echo y for each component
    # License is valid for all the standard components in versions installed from this file
    # Non-standard components: MIPS system images, preview versions, GDK (Google Glass) and Android Google TV require separate licenses, not accepted there
    yes | ${ANDROID_HOME}/tools/bin/sdkmanager  --licenses; \
    mkdir -p ${USER_HOME}/.android; \
    touch ${USER_HOME}/.android/repositories.cfg; \
    ${ANDROID_HOME}/tools/bin/sdkmanager "tools" "platform-tools"; \
    # channel = 0 (Stable), 1 (Beta), 2 (Dev), 3 (Canary)
    yes | ${ANDROID_HOME}/tools/bin/sdkmanager --update --channel=0; \
    # Please keep all sections in descending order!
    yes | ${ANDROID_HOME}/tools/bin/sdkmanager \
    "platforms;android-29" \
    "build-tools;29.0.2" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "extras;google;google_play_services" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" \
    "add-ons;addon-google_apis-google-23"
# ------------------------------------------------------
# --- Install Gradle
RUN set -eux; \
    ESUM='d0c43d14e1c70a48b82442f435d06186351a2d290d72afd5b8866f15e6d7038a'; \
    ARCHIVE='gradle-6.1-bin.zip'; \
    BINARY_URL="https://services.gradle.org/distributions/${ARCHIVE}"; \
    mkdir -p ${GRADLE_HOME}; \
    curl -LfsSo ${ARCHIVE} ${BINARY_URL}; \
    echo "${ESUM} *${USER_HOME}/${ARCHIVE}" | sha256sum -c -; \
    unzip -q ${ARCHIVE} -d ${USER_HOME}; \
    mv ${USER_HOME}/gradle-6.1/* ${GRADLE_HOME}/ && rmdir ${USER_HOME}/gradle-6.1; \
    rm ${ARCHIVE}
# ------------------------------------------------------
# --- Install Apache Maven
RUN set -eux; \
    ESUM='26ad91d751b3a9a53087aefa743f4e16a17741d3915b219cf74112bf87a438c5'; \
    ARCHIVE="apache-maven-3.6.3-bin.tar.gz"; \
    BINARY_URL="http://apache.mirrors.spacedump.net/maven/maven-3/3.6.3/binaries/${ARCHIVE}"; \
    mkdir -p ${MAVEN_HOME}; \
    curl -LfsSo ${ARCHIVE} ${BINARY_URL}; \
    echo "${ESUM} *${USER_HOME}/${ARCHIVE}" | sha256sum -c -; \
    tar -xzf ${ARCHIVE} --strip-components=1 -C ${MAVEN_HOME}; \
    rm ${ARCHIVE}
# ------------------------------------------------------
# --- Install Flutter
RUN set -eux; \
    ESUM='d792c92895623da35e1a9ccd8bc2fe84c81dd72c2c54073f56fe70625866d800'; \
    ARCHIVE='flutter_linux_v1.12.13+hotfix.5-stable.tar.xz'; \
    BINARY_URL="https://storage.googleapis.com/flutter_infra/releases/stable/linux/${ARCHIVE}"; \
    mkdir -p ${FLUTTER_HOME}; \
    curl -LfsSo ${ARCHIVE} ${BINARY_URL}; \
    echo "${ESUM} *${USER_HOME}/${ARCHIVE}" | sha256sum -c -; \
    tar -xJf ${ARCHIVE} --strip-components=1 -C ${FLUTTER_HOME}; \
    rm ${ARCHIVE}; \
    ${FLUTTER_HOME}/bin/flutter config --no-analytics; \
    ${FLUTTER_HOME}/bin/flutter precache
# ------------------------------------------------------
ENV PATH "${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${GRADLE_HOME}/bin:${FLUTTER_HOME}/bin:${PATH}"
