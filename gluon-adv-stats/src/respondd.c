
#include <respondd.h>

#include <json-c/json.h>
#include <libgluonutil.h>

#include <uci.h>

#include <string.h>


static struct json_object * get_advanced_stats(void) {
	struct uci_context *ctx = uci_alloc_context();
	if (!ctx)
		return NULL;
	ctx->flags &= ~UCI_FLAG_STRICT;

	struct uci_package *p;
	if (uci_load(ctx, "advstats", &p))
		goto error;

	struct uci_section *s = uci_lookup_section(ctx, p, "settings");
	if (!s)
		goto error;

	struct json_object *ret = json_object_new_object();

	const char *enabled = uci_lookup_option_string(ctx, s, "enabled");
	json_object_object_add(ret, "store-stats", json_object_new_boolean(enabled && !strcmp(enabled, "1")));

	uci_free_context(ctx);

	return ret;

error:
	uci_free_context(ctx);
	return NULL;
}

static struct json_object * respondd_provider_nodeinfo(void) {
	struct json_object *ret = json_object_new_object();

	json_object_object_add(ret, "advanced-stats", get_advanced_stats());

	return ret;
}


const struct respondd_provider_info respondd_providers[] = {
	{"nodeinfo", respondd_provider_nodeinfo},
	{}
};
