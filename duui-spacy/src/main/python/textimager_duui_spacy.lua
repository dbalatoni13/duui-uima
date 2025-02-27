-- Bind static classes from java
StandardCharsets = luajava.bindClass("java.nio.charset.StandardCharsets")

-- This "serialize" function is called to transform the CAS object into an stream that is sent to the annotator
-- Inputs:
--  - inputCas: The actual CAS object to serialize
--  - outputStream: Stream that is sent to the annotator, can be e.g. a string, JSON payload, ...
--  - parameters: Table/Dictonary of parameters that should be used to configure the annotator
function serialize(inputCas, outputStream, parameters)
    -- Get data from CAS
    -- For spaCy, we need the documents text and its language
    -- TODO add additional params?
    local doc_text = inputCas:getDocumentText()
    local doc_lang = inputCas:getDocumentLanguage()

    -- Encode data as JSON object and write to stream
    -- TODO Note: The JSON library is automatically included and available in all Lua scripts
    outputStream:write(json.encode({
        text = doc_text,
        lang = doc_lang,
        parameters = parameters
    }))
end

-- This "deserialize" function is called on receiving the results from the annotator that have to be transformed into a CAS object
-- Inputs:
--  - inputCas: The actual CAS object to deserialize into
--  - inputStream: Stream that is received from to the annotator, can be e.g. a string, JSON payload, ...
function deserialize(inputCas, inputStream)
    -- Get string from stream, assume UTF-8 encoding
    local inputString = luajava.newInstance("java.lang.String", inputStream:readAllBytes(), StandardCharsets.UTF_8)

    -- Parse JSON data from string into object
    local results = json.decode(inputString)

    -- Add modification annotation
    local modification_meta = results["modification_meta"]
    local modification_anno = luajava.newInstance("org.texttechnologylab.annotation.DocumentModification", inputCas)
    modification_anno:setUser(modification_meta["user"])
    modification_anno:setTimestamp(modification_meta["timestamp"])
    modification_anno:setComment(modification_meta["comment"])
    modification_anno:addToIndexes()

    -- Get meta data, this is the same for every annotation
    local meta = results["meta"]

    -- Add sentences
    for i, sent in ipairs(results["sentences"]) do
        -- Writing can be disabled via parameters
        -- Note: spaCy will still run the full pipeline, and all results are based on these results
        if sent["write_sentence"] then
            -- Create sentence annotation
            local sent_anno = luajava.newInstance("de.tudarmstadt.ukp.dkpro.core.api.segmentation.type.Sentence", inputCas)
            sent_anno:setBegin(sent["begin"])
            sent_anno:setEnd(sent["end"])
            sent_anno:addToIndexes()

            -- Create annotator meta data annotation, using the base meta data
            local meta_anno = luajava.newInstance("org.texttechnologylab.annotation.SpacyAnnotatorMetaData", inputCas)
            meta_anno:setReference(sent_anno)
            meta_anno:setName(meta["name"])
            meta_anno:setVersion(meta["version"])
            meta_anno:setModelName(meta["modelName"])
            meta_anno:setModelVersion(meta["modelVersion"])
            meta_anno:setSpacyVersion(meta["spacyVersion"])
            meta_anno:setModelLang(meta["modelLang"])
            meta_anno:setModelSpacyVersion(meta["modelSpacyVersion"])
            meta_anno:setModelSpacyGitVersion(meta["modelSpacyGitVersion"])
            meta_anno:addToIndexes()
        end
    end

    -- Add tokens
    -- Save all tokens, to allow for retrieval in dependencies
    local all_tokens = {}
    for i, token in ipairs(results["tokens"]) do
        -- Save current token
        local token_anno = nil
        if token["write_token"] then
            -- Create token annotation
            token_anno = luajava.newInstance("de.tudarmstadt.ukp.dkpro.core.api.segmentation.type.Token", inputCas)
            token_anno:setBegin(token["begin"])
            token_anno:setEnd(token["end"])
            token_anno:addToIndexes()

            -- Save current token using its index
            -- Note: Lua starts counting at 1
            all_tokens[i-1] = token_anno

            -- Create meta data for this token
            local meta_anno = luajava.newInstance("org.texttechnologylab.annotation.SpacyAnnotatorMetaData", inputCas)
            meta_anno:setReference(token_anno)
            meta_anno:setName(meta["name"])
            meta_anno:setVersion(meta["version"])
            meta_anno:setModelName(meta["modelName"])
            meta_anno:setModelVersion(meta["modelVersion"])
            meta_anno:setSpacyVersion(meta["spacyVersion"])
            meta_anno:setModelLang(meta["modelLang"])
            meta_anno:setModelSpacyVersion(meta["modelSpacyVersion"])
            meta_anno:setModelSpacyGitVersion(meta["modelSpacyGitVersion"])
            meta_anno:addToIndexes()
        end

        if token["write_lemma"] then
            local lemma_anno = luajava.newInstance("de.tudarmstadt.ukp.dkpro.core.api.segmentation.type.Lemma", inputCas)
            lemma_anno:setBegin(token["begin"])
            lemma_anno:setEnd(token["end"])
            lemma_anno:setValue(token["lemma"])
            lemma_anno:addToIndexes()

            -- If there is a token, i.e. writing is not disabled for tokens, add this lemma infos to the token
            if token_anno ~= nil then
                token_anno:setLemma(lemma_anno)
            end

            local meta_anno = luajava.newInstance("org.texttechnologylab.annotation.SpacyAnnotatorMetaData", inputCas)
            meta_anno:setReference(lemma_anno)
            meta_anno:setName(meta["name"])
            meta_anno:setVersion(meta["version"])
            meta_anno:setModelName(meta["modelName"])
            meta_anno:setModelVersion(meta["modelVersion"])
            meta_anno:setSpacyVersion(meta["spacyVersion"])
            meta_anno:setModelLang(meta["modelLang"])
            meta_anno:setModelSpacyVersion(meta["modelSpacyVersion"])
            meta_anno:setModelSpacyGitVersion(meta["modelSpacyGitVersion"])
            meta_anno:addToIndexes()
        end

        if token["write_pos"] then
            -- TODO Add full pos mapping for different pos types
            local pos_anno = luajava.newInstance("de.tudarmstadt.ukp.dkpro.core.api.lexmorph.type.pos.POS", inputCas)
            pos_anno:setBegin(token["begin"])
            pos_anno:setEnd(token["end"])
            pos_anno:setPosValue(token["pos"])
            pos_anno:setCoarseValue(token["pos_coarse"])
            pos_anno:addToIndexes()

            if token_anno ~= nil then
                token_anno:setPos(pos_anno)
            end

            local meta_anno = luajava.newInstance("org.texttechnologylab.annotation.SpacyAnnotatorMetaData", inputCas)
            meta_anno:setReference(pos_anno)
            meta_anno:setName(meta["name"])
            meta_anno:setVersion(meta["version"])
            meta_anno:setModelName(meta["modelName"])
            meta_anno:setModelVersion(meta["modelVersion"])
            meta_anno:setSpacyVersion(meta["spacyVersion"])
            meta_anno:setModelLang(meta["modelLang"])
            meta_anno:setModelSpacyVersion(meta["modelSpacyVersion"])
            meta_anno:setModelSpacyGitVersion(meta["modelSpacyGitVersion"])
            meta_anno:addToIndexes()
        end

        if token["write_morph"] then
            local morph_anno = luajava.newInstance("de.tudarmstadt.ukp.dkpro.core.api.lexmorph.type.morph.MorphologicalFeatures", inputCas)
            morph_anno:setBegin(token["begin"])
            morph_anno:setEnd(token["end"])
            morph_anno:setValue(token["morph"])

            -- Add detailed infos, if available
            if token["morph_details"]["gender"] ~= nil then
                morph_anno:setGender(token["morph_details"]["gender"])
            end
            if token["morph_details"]["number"] ~= nil then
                morph_anno:setNumber(token["morph_details"]["number"])
            end
            if token["morph_details"]["case"] ~= nil then
                morph_anno:setCase(token["morph_details"]["case"])
            end
            if token["morph_details"]["degree"] ~= nil then
                morph_anno:setDegree(token["morph_details"]["degree"])
            end
            if token["morph_details"]["verbForm"] ~= nil then
                morph_anno:setVerbForm(token["morph_details"]["verbForm"])
            end
            if token["morph_details"]["tense"] ~= nil then
                morph_anno:setTense(token["morph_details"]["tense"])
            end
            if token["morph_details"]["mood"] ~= nil then
                morph_anno:setMood(token["morph_details"]["mood"])
            end
            if token["morph_details"]["voice"] ~= nil then
                morph_anno:setVoice(token["morph_details"]["voice"])
            end
            if token["morph_details"]["definiteness"] ~= nil then
                morph_anno:setDefiniteness(token["morph_details"]["definiteness"])
            end
            if token["morph_details"]["person"] ~= nil then
                morph_anno:setPerson(token["morph_details"]["person"])
            end
            if token["morph_details"]["aspect"] ~= nil then
                morph_anno:setAspect(token["morph_details"]["aspect"])
            end
            if token["morph_details"]["animacy"] ~= nil then
                morph_anno:setAnimacy(token["morph_details"]["animacy"])
            end
            if token["morph_details"]["gender"] ~= nil then
                morph_anno:setNegative(token["morph_details"]["negative"])
            end
            if token["morph_details"]["numType"] ~= nil then
                morph_anno:setNumType(token["morph_details"]["numType"])
            end
            if token["morph_details"]["possessive"] ~= nil then
                morph_anno:setPossessive(token["morph_details"]["possessive"])
            end
            if token["morph_details"]["pronType"] ~= nil then
                morph_anno:setPronType(token["morph_details"]["pronType"])
            end
            if token["morph_details"]["reflex"] ~= nil then
                morph_anno:setReflex(token["morph_details"]["reflex"])
            end
            if token["morph_details"]["transitivity"] ~= nil then
                morph_anno:setTransitivity(token["morph_details"]["transitivity"])
            end

            morph_anno:addToIndexes()

            if token_anno ~= nil then
                token_anno:setMorph(morph_anno)
            end

            local meta_anno = luajava.newInstance("org.texttechnologylab.annotation.SpacyAnnotatorMetaData", inputCas)
            meta_anno:setReference(morph_anno)
            meta_anno:setName(meta["name"])
            meta_anno:setVersion(meta["version"])
            meta_anno:setModelName(meta["modelName"])
            meta_anno:setModelVersion(meta["modelVersion"])
            meta_anno:setSpacyVersion(meta["spacyVersion"])
            meta_anno:setModelLang(meta["modelLang"])
            meta_anno:setModelSpacyVersion(meta["modelSpacyVersion"])
            meta_anno:setModelSpacyGitVersion(meta["modelSpacyGitVersion"])
            meta_anno:addToIndexes()
        end
    end

    -- Add dependencies
    for i, dep in ipairs(results["dependencies"]) do
        if dep["write_dep"] then
            -- Create specific annotation based on type
            local dep_anno
            if dep["type"] == "ROOT" then
                dep_anno = luajava.newInstance("de.tudarmstadt.ukp.dkpro.core.api.syntax.type.dependency.ROOT", inputCas)
                dep_anno:setDependencyType("--")
            else
                dep_anno = luajava.newInstance("de.tudarmstadt.ukp.dkpro.core.api.syntax.type.dependency.Dependency", inputCas)
                dep_anno:setDependencyType(dep["type"])
            end

            dep_anno:setBegin(dep["begin"])
            dep_anno:setEnd(dep["end"])
            dep_anno:setFlavor(dep["flavor"])

            -- Get needed tokens via indices
            governor_token = all_tokens[dep["governor_ind"]]
            if governor_token ~= nil then
                dep_anno:setGovernor(governor_token)
            end

            dependent_token = all_tokens[dep["dependent_ind"]]
            if governor_token ~= nil then
                dep_anno:setDependent(dependent_token)
            end

            if governor_token ~= nil and dependent_token ~= nil then
                dependent_token:setParent(governor_token)
            end

            dep_anno:addToIndexes()

            local meta_anno = luajava.newInstance("org.texttechnologylab.annotation.SpacyAnnotatorMetaData", inputCas)
            meta_anno:setReference(dep_anno)
            meta_anno:setName(meta["name"])
            meta_anno:setVersion(meta["version"])
            meta_anno:setModelName(meta["modelName"])
            meta_anno:setModelVersion(meta["modelVersion"])
            meta_anno:setSpacyVersion(meta["spacyVersion"])
            meta_anno:setModelLang(meta["modelLang"])
            meta_anno:setModelSpacyVersion(meta["modelSpacyVersion"])
            meta_anno:setModelSpacyGitVersion(meta["modelSpacyGitVersion"])
            meta_anno:addToIndexes()
        end
    end

    -- Add entities
    for i, ent in ipairs(results["entities"]) do
        if ent["write_entity"] then
            local ent_anno = luajava.newInstance("de.tudarmstadt.ukp.dkpro.core.api.ner.type.NamedEntity", inputCas)
            ent_anno:setBegin(ent["begin"])
            ent_anno:setEnd(ent["end"])
            ent_anno:setValue(ent["value"])
            ent_anno:addToIndexes()

            local meta_anno = luajava.newInstance("org.texttechnologylab.annotation.SpacyAnnotatorMetaData", inputCas)
            meta_anno:setReference(ent_anno)
            meta_anno:setName(meta["name"])
            meta_anno:setVersion(meta["version"])
            meta_anno:setModelName(meta["modelName"])
            meta_anno:setModelVersion(meta["modelVersion"])
            meta_anno:setSpacyVersion(meta["spacyVersion"])
            meta_anno:setModelLang(meta["modelLang"])
            meta_anno:setModelSpacyVersion(meta["modelSpacyVersion"])
            meta_anno:setModelSpacyGitVersion(meta["modelSpacyGitVersion"])
            meta_anno:addToIndexes()
        end
    end
end
