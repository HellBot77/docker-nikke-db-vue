FROM alpine/git AS base

ARG TAG=latest
RUN git clone https://github.com/Nikke-db/nikke-db-vue.git && \
    cd nikke-db-vue && \
    ([[ "$TAG" = "latest" ]] || git checkout ${TAG}) && \
    rm -rf .git && \
    sed -i 's/enum globalParams/enum _globalParams/' src/utils/enum/globalParams.ts && \
    PATCH="\
        let globalParams: { [key: string]: string } = { ..._globalParams }\n\
        try {\n\
            const request = new XMLHttpRequest()\n\
            request.open('GET', '/nikke-db.txt', false)\n\
            request.send()\n\
            if (request.status === 200) {\n\
                for (let key in globalParams) {\n\
                    if (globalParams[key].startsWith(_globalParams.NIKKE_DB)) {\n\
                        globalParams[key] = request.responseText + globalParams[key].substring(_globalParams.NIKKE_DB.length)\n\
                    }\n\
                }\n\
            }\n\
        } catch (e) {\n\
            console.error(e)\n\
        }\
        " && \
    sed -i "/enum messagesEnum/i$PATCH" src/utils/enum/globalParams.ts

FROM node:alpine AS build

WORKDIR /nikke-db-vue
COPY --from=base /git/nikke-db-vue .
RUN npm install && \
    npm run build

FROM lipanski/docker-static-website

COPY --from=build /nikke-db-vue/dist .
