# REF Compliance Checker for EPrints

## REF2029 Compliance Updates
Please see the ref2029 and ref2029_epm branches for ingredient and Bazaar EPM updates to the REF CC plugin for the new OA compliance criteria for publications published from January 2026 onwards.

**Key changes include:**
* New REF2029_CC DataObj for storing all data and running OA compliance checks.
* Updated REF CC tab and workflow stages to display new rules and exception options.
* New "REF 2029 Compliance (Jan 26 or later)" report for items published from January 2026 or later.
* Tidying up of old reports which are condensed down to "REF Compliance (pre Jan 26)" and "REF Compliance - Exceptions (pre Jan 26)".

**Installation:**
If updating from the old plugin, you will need to run `epadming recommit <repoid> eprint` to ensure all EPrints are updated with a new REF CC Dataobj where appropriate.

The EPrints deposit workflow hefce_oa stage will also need updating as follows:
```
  <stage name="hefce_oa" required_by="hefce_oa">
    <epc:choose>
      <epc:when test="ref2029_cc.property('scope') = '26-28'">
        <component><field ref="hoa_emb_len"/></component>
        <component><field ref="hoa_ref_pan"/></component>
        <component type="REF2029">
          <field ref="ref2029_gold_oa"/>
          <field ref="ref2029_pub_agreement"/>
          <field ref="ref2029_pre_compliant"/>
          <field ref="ref2029_pre_compliant_txt"/>
          <field ref="ref2029_override"/>
          <field ref="ref2029_ex_dep"/>
          <field ref="ref2029_ex_dep_txt"/>
          <field ref="ref2029_ex_acc"/>
          <field ref="ref2029_ex_acc_txt"/>
          <field ref="ref2029_ex_tec"/>
          <field ref="ref2029_ex_tec_txt"/>
          <field ref="ref2029_ex_fur"/>
          <field ref="ref2029_ex_fur_txt"/>
        </component>
      </epc:when>
      <epc:otherwise>
    <component type="Field::Multi">
      <title>Pre-Compliance</title>
      <field ref="hoa_override"/>
      <field ref="hoa_override_txt"/>
    </component>
    <component>
      <field ref="hoa_exclude"/>
    </component>
    <component>
      <field ref="hoa_pre_pub"/>
    </component>
    <component>
      <field ref="hoa_gold"/>
    </component>
    <component>
      <field ref="hoa_emb_len"/>
    </component>
    <component>
      <field ref="hoa_ref_pan"/>
    </component>
    <component type="Field::Multi">
      <title>Deposit Exceptions</title>
      <field ref="hoa_ex_dep"/>
      <field ref="hoa_ex_dep_txt"/>
    </component>
    <component type="Field::Multi">
      <title>Access Exceptions</title>
      <field ref="hoa_ex_acc"/>
      <field ref="hoa_ex_acc_txt"/>
    </component>
    <component type="Field::Multi">
      <title>Technical Exceptions</title>
      <field ref="hoa_ex_tec"/>
      <field ref="hoa_ex_tec_txt"/>
    </component>
    <component type="Field::Multi">
      <title>Further Exceptions</title>
      <field ref="hoa_ex_fur"/>
      <field ref="hoa_ex_fur_txt"/>
    </component>
  </epc:otherwise>
  </epc:choose>
  </stage>
```

**Link to EPrints Wiki Page**

New documentation on Wiki (derived from old documentation): https://wiki.eprints.org/w/REF_CC

**Original REF CC Documentation**

Old documentation: See http://eprintsug.github.io/hefce_oa/ for details.
