USE [VK]
GO
/****** Object:  StoredProcedure [discovering].[merge_groups]    Script Date: 12.12.2017 12:06:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter proc [discovering].[merge_posts]
as

MERGE dim.posts AS target  
USING staging.posts AS source 
  ON target.source_id = source.source_id
  and target.is_posted_by_user = source.is_posted_by_user
  and target.post_id = source.post_id
when matched then 
    update set
        target.comments = source.comments
      , target.likes = source.likes
      , target.reposts = source.reposts
      , target.views = source.views
      , target.updated_dt_precise = getdate()
      --колонки repost_from_source_id_signed, repost_from_post_id, posted_dt_precise не должны меняться со временем
      --posted_dt_precise not null, рушим этот констрейнт, если какая-то из этих колонок поменялась
      , target.posted_dt_precise = iif
          (
              target.posted_dt_precise = source.posted_dt_precise
              and isnull(target.repost_from_source_id_signed, 0) = isnull(source.repost_from_source_id_signed, 0)
              and isnull(target.repost_from_post_id, 0) = isnull(source.repost_from_post_id, 0)
            , target.posted_dt_precise
            , null
          )
WHEN NOT MATCHED by target THEN   
  INSERT 
    (
        source_id, is_posted_by_user, post_id
      , comments, likes, reposts, views
      , repost_from_source_id_signed, repost_from_post_id
      , posted_dt_precise
      , created_dt_precise, updated_dt_precise
    )
  VALUES
    (
        source.source_id, source.is_posted_by_user, source.post_id
      , source.comments, source.likes, source.reposts, source.views
      , iif(source.repost_from_source_id_signed = 0, null, source.repost_from_source_id_signed) --repost_from_source_id_signed
      , iif(source.repost_from_post_id = 0, null, source.repost_from_post_id) --repost_from_post_id
      , source.posted_dt_precise
      , getdate() --created_dt_precise
      , getdate() --updated_dt_precise
    )
;

