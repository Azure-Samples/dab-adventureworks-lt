/*
    Table to publish as API
*/
drop table if exists #t;
select         
    [name] as entity_name,
    [name] as table_name,
    object_id,
    schema_id
into
    #t
from 
    sys.tables where [name] not in ('AdventureWorksDWBuildVersion', 'DatabaseLog', 'NewFactCurrencyRate')
;
-- select * from #t;

/*
    Find many-to-one relationships between tables
*/
drop table if exists #r;
select      
    t.object_id,
    object_name(t.object_id) as entity,
    referenced_object_id,  
    object_name(referenced_object_id) as [target.entity],
    cast(iif(referenced_object_id is null, null, 'one') as varchar(10)) as cardinality,
    json_array((
                select string_agg([name], ',') 
                from sys.foreign_key_columns fkc 
                inner join sys.columns c on 
                    fkc.parent_object_id = c.object_id and fkc.parent_column_id = c.column_id 
                where 
                    fk.object_id = fkc.constraint_object_id
                )) as [source.fields],
    json_array((
                select string_agg([name], ',') 
                from sys.foreign_key_columns fkc 
                inner join sys.columns c on 
                    fkc.referenced_object_id = c.object_id and fkc.referenced_column_id = c.column_id 
                where 
                    fk.object_id = fkc.constraint_object_id
    )) as [target.fields]
into    
    #r
from
    #t t 
left join  
    sys.foreign_keys fk on fk.parent_object_id = t.object_id
;
select * from #r;

/*
    Add inverse, one-to-many, relationships
*/
insert into 
    #r 
select 
    referenced_object_id as object_id,
    [target.entity] as entity,
    object_id as referenced_object_id, 
    entity as [target.entity],
    'many' as cardinality,
    [target.fields] as [source.fields],
    [source.fields] as [target.fields] 
from 
    #r
where   
    referenced_object_id is not null
;
select * from #r;

/*
    Build relationship JSON config for each entity
*/
drop table if exists #jr;
select
    object_id,    
    entity,
    json_query(( '{' + (string_agg(
        '"' + [target.entity] + '": ' + 
            json_object(
                    'cardinality': cardinality,
                    'target.entity': [target.entity],
                    'source.fields': json_query([source.fields]),
                    'target.fields': json_query([target.fields])
            )
        ,
        ','
        )
    ) + '}')) as relationships
into
    #jr
from
    #r
group by
    object_id,
    entity
;
select * from #jr;

/*
    Build complete JSON config for each entity
*/
drop table if exists #c;
select 
    [entity_name] as entity,
    json_object(
        'source': quotename(schema_name(schema_id)) + '.' + quotename(table_name),
        'permissions': json_array(
            json_object(
                'role': 'anonymous',
                'actions': json_array(json_object('action':'*'))
            )
        ),
        'relationships': json_query(isnull(r.relationships, '{}'))
    ) as config
into
    #c
from 
    #t t
left outer join
    #jr r on t.object_id = r.object_id
;
select * from #c;

/*
    Create the final entities config section
*/
select 
    json_object('entities': json_query('{' + string_agg('"' + entity + '": ' + config, ',') + '}')) as entities_config
from
    #c
