{*
* Copyright (C) 2017 thirty bees
*
* NOTICE OF LICENSE
*
* This source file is subject to the Academic Free License (AFL 3.0)
* that is bundled with this package in the file LICENSE.md
* It is also available through the world-wide-web at this URL:
* http://opensource.org/licenses/afl-3.0.php
* If you did not receive a copy of the license and are unable to
* obtain it through the world-wide-web, please send an email
* to contact@thirtybees.com so we can send you a copy immediately.
*
* @author    thirty bees <contact@thirtybees.com>
* @copyright 2017 thirty bees
* @license   http://opensource.org/licenses/afl-3.0.php  Academic Free License (AFL 3.0)
*}
{* Vue store *}
{include file=ElasticSearch::tpl('hook/vue/store.vue.tpl')}
{* Include autocomplete if enabled *}
{if $autocomplete}{include file=ElasticSearch::tpl('hook/vue/autocomplete.vue.tpl')}{/if}

{* Components *}
{include file=ElasticSearch::tpl('hook/vue/column.vue.tpl')}
{include file=ElasticSearch::tpl('hook/vue/results.vue.tpl')}

{* Dependencies *}
{include file=ElasticSearch::tpl('hook/vue/column-left.vue.tpl')}
{include file=ElasticSearch::tpl('hook/vue/column-right.vue.tpl')}

{* Template file *}
{capture name="template"}{include file=ElasticSearch::tpl('hook/vue/main-search.html.tpl')}{/capture}
<script type="text/javascript">
  (function () {
    var $target = $('#es-searchbox');
    if (!$target.length) {
      return;
    }

    function getHashValue(key) {
      if (typeof key !== 'string') {
        key = '';
      } else {
        key = key.toLowerCase();
      }

      var keyAndHash = location.hash.toLowerCase().match(new RegExp(key + '=([^&]*)'));
      var value = '';

      if (keyAndHash) {
        value = keyAndHash[1];
      }

      return value;
    }

    {* If dev mode, enable Vue dev mode as well *}
    {if $smarty.const._PS_MODE_DEV_}Vue.config.devtools = true;{/if}

    // Initialize the ElasticsearchModule object if it does not exist
    window.ElasticsearchModule = window.ElasticsearchModule || {ldelim}{rdelim};

    window.ElasticsearchModule.mainSearch = new Vue({
      created: function() {
        this.$store.commit('setQuery', {
          query: getHashValue('q'),
          showSuggestions: false
        });
      },
      delimiters: ['%%', '%%'],
      el: '#es-searchbox',
      template: '{$smarty.capture.template|escape:'javascript':'UTF-8'}',
      store: window.ElasticsearchModule.store,
      components: {
        ElasticsearchColumn: window.ElasticsearchModule.components.column,
        ElasticsearchResults: window.ElasticsearchModule.components.results,
        {if $autocomplete}ElasticsearchAutocomplete: window.ElasticsearchModule.components.autocomplete,{/if}
      },
      computed: {
        query: function () {
          return this.$store.state.query;
        },
        results: function () {
          return this.$store.state.results;
        },
        suggestions: function () {
          return this.$store.state.suggestions;
        },
        selected: function () {
          if (this.suggestionIndex >= 0
            && this.$store.state.suggestions[this.suggestionIndex]
            && this.$store.state.suggestions[this.suggestionIndex]['_id']
          ) {
            return this.$store.state.suggestions[this.suggestionIndex]['_id'];
          }

          return -1;
        }
      },
      data: function data() {
        return {
          suggestionIndex: -1
        };
      },
      methods: {
        queryChangedHandler: function (event) {
          this.$store.commit('setQuery', {
            query: event.target.value,
            showSuggestions: true
          });
        },
        submitHandler: function (event) {
          // Do not submit the fallback form
          event.preventDefault();

          if (this.suggestionIndex >= 0
            && this.$store.state.suggestions[this.suggestionIndex]
            && this.$store.state.suggestions[this.suggestionIndex]['_source']
          ) {
            // Go directly to the select product
            window.location.href = this.$store.state.suggestions[this.suggestionIndex]['_source']['link'];
          } else {
            // Go to search page
            window.location.href = '{$link->getModuleLink('elasticsearch', 'search', [], true)|escape:'javascript':'UTF-8'}#q=' + this.$store.state.query;
          }

          this.$store.commit('eraseSuggestions');
        },
        suggestionDownHandler: function (event) {
          // Prevent the cursor from moving
          event.preventDefault();

          // Down means to traverse down on the list, effectively incrementing the index
          var index = this.suggestionIndex;
          index++;
          if (index > this.$store.state.suggestions.length - 1) {
            index = this.$store.state.suggestions.length - 1;
          }

          this.suggestionIndex = index;
        },
        suggestionUpHandler: function (event) {
          // Prevent the cursor from moving
          event.preventDefault();

          // Up means to traverse up on the list, effectively decrementing the index
          var index = this.suggestionIndex;
          index--;
          if (index < -1) {
            index = -1;
          }

          this.suggestionIndex = index;
        },
        focusHandler: function () {
          this.suggestionIndex = -1;
        },
        blurHandler: function () {
          $elasticsearchResults = $('#elasticsearch-results');
          if ($elasticsearchResults.length && !$elasticsearchResults.is(':hover')) {
            this.$store.commit('eraseSuggestions');
          }
        },
        getTaxRate: function (idTaxRulesGroup) {
          var taxRules = {TaxRulesGroup::getAssociatedTaxRatesByIdCountry(Context::getContext()->country->id)|json_encode};

          if (taxRules[idTaxRulesGroup]) {
            return parseFloat(taxRules[idTaxRulesGroup], 10);
          }

          return 0;
        }
      }
    })
  }());
</script>
