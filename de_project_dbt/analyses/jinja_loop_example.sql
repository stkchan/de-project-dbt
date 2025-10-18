{% set countries = ["Japan", "USA", "China", "France", "Spain", "Thailand", "Cambodia"] %}

{% for i in countries %}
    {% if i != "Cambodia" %}
        {{ i }} is allowed
    {% else %}
        {{ i }} is restricted
    {% endif %}
{% endfor %}
