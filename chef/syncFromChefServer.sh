#download environments
for env in `knife environment list`; do
  knife environment show $env --format=json > environments/$env.json
  echo "env: $env"
done

#download roles
for role in `knife role list`; do
  knife role show $role --format=json > roles/$role.json
  echo "role: $role"
done

#download cookbooks
for cookbook in `knife cookbook list | cut -f3 -d' '`; do
  knife cookbook download $cookbook
done

