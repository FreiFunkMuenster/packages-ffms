/*
  Copyright (c) 2016, Matthias Schiffer <mschiffer@universe-factory.net>
  All rights reserved.
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    1. Redistributions of source code must retain the above copyright notice,
       this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#include <respondd.h>

#include <json-c/json.h>
#include <libgluonutil.h>

#include <uci.h>

#include <string.h>

// function out of the gluon-node-info package
struct uci_section * get_first_section(struct uci_package *p, const char *type) {
	struct uci_element *e;
	uci_foreach_element(&p->sections, e) {
		struct uci_section *s = uci_to_section(e);
		if (!strcmp(s->type, type))
			return s;
	}

	return NULL;
}

// function out of the gluon-node-info package
const char * get_first_option(struct uci_context *ctx, struct uci_package *p, const char *type, const char *option) {
	struct uci_section *s = get_first_section(p, type);
	if (s)
		return uci_lookup_option_string(ctx, s, option);
	else
		return NULL;
}

//written by RobWei
static struct json_object * get_advanced_stats(void) {
	struct json_object *ret = json_object_new_object();
	struct uci_context *ctx = uci_alloc_context();
	if (!ctx)
		goto error;
	ctx->flags &= ~UCI_FLAG_STRICT;

	struct uci_package *p;
	if (uci_load(ctx, "gluon-advanced-config", &p))
		goto error;

	const char *enabled = get_first_option(ctx, p, "advstats", "enabled");
	json_object_object_add(ret, "store-stats", json_object_new_boolean(enabled && !strcmp(enabled, "1")));

	uci_free_context(ctx);
	return ret;

 error:
	uci_free_context(ctx);
	json_object_object_add(ret, "store-stats", json_object_new_boolean(0));
	return ret;
}

static struct json_object * respondd_provider_nodeinfo(void) {
	struct json_object *retadvstats = json_object_new_object();
	json_object_object_add(retadvstats, "advanced-stats", get_advanced_stats());
	return retadvstats;
}

const struct respondd_provider_info respondd_providers[] = {
	{"nodeinfo", respondd_provider_nodeinfo},
	{}
};
