FROM ubuntu:latest
# ------------------------------------------------------
# --- Environments and base directories
ENV ANDROID_HOME="/home/stolas69/sdk/android" \
    FLUTTER_HOME="/home/stolas69/sdk/flutter" \
    GRADLE_HOME="/home/stolas69/tools/gradle" \
    MAVEN_HOME="/home/stolas69/tools/maven" \
    USER_HOME="/home/stolas69" \
    DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    JAVA_VERSION="jdk8u232-b09"
RUN apt-get update -qq \
    # --- Disable installing reccommended and suggested packages by default
    # --- to keep the image minimal
    && echo 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";' | tee /etc/apt/apt.conf.d/99norecommend \
    # --- Generate en_US.UTF-8 locales
    && apt-get install -y locales \
    && locale-gen en_US.UTF-8 \
    # --- Install required packages
    && apt-get -y install git curl ca-certificates unzip xz-utils make jq \
    && dpkg --add-architecture i386 \
    && apt-get update -qq \
    && apt-get install -y libc6:i386 libstdc++6:i386 libgcc1:i386 libncurses5:i386 libz1:i386 net-tools \
    && apt-get clean
# ------------------------------------------------------
# --- Install adoptjdk
RUN set -eux; \
    ESUM='7b7884f2eb2ba2d47f4c0bf3bb1a2a95b73a3a7734bd47ebf9798483a7bcc423'; \
    ARCHIVE='OpenJDK8U-jdk_x64_linux_hotspot_8u232b09.tar.gz'; \
    BINARY_URL="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u232-b09/${ARCHIVE}"; \
    curl -LfsSo /tmp/${ARCHIVE} ${BINARY_URL}; \
    echo "${ESUM} */tmp/${ARCHIVE}" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    tar -xzf /tmp/${ARCHIVE} --strip-components=1 -C /opt/java/openjdk; \
    rm /tmp/${ARCHIVE}
ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"
# ------------------------------------------------------
# --- Create user and home directory
RUN useradd --create-home --shell /bin/bash stolas69
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
    echo "${ESUM} *${USER_HOME}/${ARCHIVE}" | sha256sum -c -; \
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
RUN mkdir -p ${FLUTTER_HOME}; \
   git clone -b stable https://github.com/flutter/flutter.git ${FLUTTER_HOME}; \
   ${FLUTTER_HOME}/bin/flutter config --no-analytics; \
   ${FLUTTER_HOME}/bin/flutter precache
# ------------------------------------------------------
ENV PATH "${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${GRADLE_HOME}/bin:${FLUTTER_HOME}/bin:${MAVEN_HOME}/bin:${PATH}"
