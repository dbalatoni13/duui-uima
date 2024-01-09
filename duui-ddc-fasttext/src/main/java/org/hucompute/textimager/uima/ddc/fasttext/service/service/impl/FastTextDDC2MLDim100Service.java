package org.hucompute.textimager.uima.ddc.fasttext.service.service.impl;

import io.quarkus.arc.Lock;
import org.hucompute.textimager.uima.ddc.fasttext.service.service.FastTextDDC2Service;

import javax.annotation.PreDestroy;
import javax.inject.Singleton;

@Lock
@Singleton
public class FastTextDDC2MLDim100Service extends FastTextDDC2Service {
    FastTextDDC2MLDim100Service() throws Exception {
        this(
                "",
                "",
                ""
        );
    }

    FastTextDDC2MLDim100Service(String disambigTag, String disambigLabelReplace, String disambigLabelReplaceWith) throws Exception {
        // TODO paths in container are absolute!
        // TODO WICHTIG die parameter weiter anpassen an die Daten aus der TI Config
        super(
                "/home/stud_homes/baumartz/mnt/resources/nlp/bin/categorization/fastText_modern_for_duui_annotators/fasttext",
                "_ml,/home/stud_homes/baumartz/mnt/resources/nlp/models/categorization/ddc/ddc_2023/wikipedia_lemma_nopunct_pos_withcategories__en__de_nofunction__ddc2__dim100_lr0.2_lrur150_mincount5_epoch100.bin,98",
                true,
                1,
                true,
                true,
                "/home/stud_homes/baumartz/mnt/resources/nlp/models/categorization/am_posmap.txt",
                true,
                false,
                false, // TODO was true originally
                false,
                100,
                "ddc2;dim100;ddc_2023/wikipedia_lemma_nopunct_pos_withcategories__en__de_nofunction__ddc2__dim100_lr0.2_lrur150_mincount5_epoch100.bin",
                disambigTag,
                disambigLabelReplace,
                disambigLabelReplaceWith
        );
    }

    @PreDestroy
    void preDestroy() {
        this.exit();
    }
}
